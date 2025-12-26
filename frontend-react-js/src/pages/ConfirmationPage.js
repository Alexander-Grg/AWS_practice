import './ConfirmationPage.css';
import React from "react";
import { useLocation, useNavigate } from 'react-router-dom';
import { ReactComponent as Logo } from '../components/svg/logo.svg';
import { Auth } from 'aws-amplify';

export default function ConfirmationPage() {
  const [email, setEmail] = React.useState('');
  const [code, setCode] = React.useState('');
  const [errors, setErrors] = React.useState('');
  const [codeSent, setCodeSent] = React.useState(false);
  const [isLoading, setIsLoading] = React.useState(false); // 1. Add loading state

  const location = useLocation();
  const navigate = useNavigate();

  const code_onchange = (event) => {
    setCode(event.target.value);
  }

  const email_onchange = (event) => {
    setEmail(event.target.value);
  }

  const resend_code = async (event) => {
    setErrors('');
    try {
      await Auth.resendSignUp(email);
      console.log('code resent successfully');
      setCodeSent(true);
    } catch (err) {
      console.log(err);
      if (err.message === 'Username cannot be empty'){
        setErrors("You need to provide an email in order to send Resend Activation Code");
      } else if (err.message === "Username/client id combination not found."){
        setErrors("Email is invalid or cannot be found.");
      }
    }
  }

  const onsubmit = async (event) => {
    event.preventDefault();
    setErrors('');
    setIsLoading(true); // 2. Start loading

    try {
      await Auth.confirmSignUp(email, code);
      // If successful, redirect
      navigate(`/signin?email=${encodeURIComponent(email)}`);
    } catch (error) {
      console.log(error);
      
      // 3. Handle "User is already confirmed" gracefully
      // This happens if the first request succeeded on backend but timed out on frontend
      if (error.message === 'User cannot be confirmed. Current status is CONFIRMED') {
          navigate(`/signin?email=${encodeURIComponent(email)}`);
          return;
      }

      setErrors(error.message);
      setIsLoading(false); // Stop loading only if we are truly stuck
    }
  }

  let el_errors;
  if (errors){
    el_errors = <div className='errors'>{errors}</div>;
  }

  let code_button;
  if (codeSent){
    code_button = <div className="sent-message">A new activation code has been sent to your email</div>
  } else {
    code_button = <button className="resend" onClick={resend_code}>Resend Activation Code</button>;
  }

  React.useEffect(()=>{
    const query = new URLSearchParams(location.search);
    const emailParam = query.get('email');
    if (emailParam) {
      setEmail(emailParam);
    }
  }, [location.search]);

  return (
    <article className="confirm-article">
      <div className='recover-info'>
        <Logo className='logo' />
      </div>
      <div className='recover-wrapper'>
        <form
          className='confirm_form'
          onSubmit={onsubmit}
        >
          <h2>Confirm your Email</h2>
          <div className='fields'>
            <div className='field text_field email'>
              <label>Email</label>
              <input
                type="text"
                value={email}
                onChange={email_onchange}
                disabled={true} 
              />
            </div>
            <div className='field text_field code'>
              <label>Confirmation Code</label>
              <input
                type="text"
                value={code}
                onChange={code_onchange} 
              />
            </div>
          </div>
          {el_errors}
          <div className='submit'>
            {/* 4. Disable button while loading */}
            <button type='submit' disabled={isLoading}>
                {isLoading ? 'Processing...' : 'Confirm Email'}
            </button>
          </div>
        </form>
      </div>
      {code_button}
    </article>
  );
}