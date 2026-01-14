import './SigninPage.css';
import React from "react";
import {ReactComponent as Logo} from '../components/svg/logo.svg';
import { Link } from "react-router-dom";

// [TODO] Authenication
import { Auth } from 'aws-amplify';

export default function SigninPage() {

  const [email, setEmail] = React.useState('');
  const [password, setPassword] = React.useState('');
  const [errors, setErrors] = React.useState('');
  const [loading, setLoading] = React.useState(false);

  const onsubmit = async (event) => {
    event.preventDefault();
    
    if (loading) return;
    
    setErrors('');
    setLoading(true); 

    try {
      const user = await Auth.signIn(email, password);
      localStorage.setItem("access_token", user.signInUserSession.accessToken.jwtToken);
      window.location.href = "/";
    } catch (error) {
      console.log('Error signing in:', error);
      setLoading(false); 

      if (error.code === 'UserNotConfirmedException') {
        window.location.href = "/confirm";
        return;
      }
      setErrors(error.message);
    }
  }

  const email_onchange = (event) => {
    setEmail(event.target.value);
  }
  const password_onchange = (event) => {
    setPassword(event.target.value);
  }

  let el_errors;
  if (errors){
    el_errors = <div className='errors'>{errors}</div>;
  }

  return (
    <article className="signin-article">
      <div className='signin-info'>
        <Logo className='logo' />
      </div>
      <div className='signin-wrapper'>
        <form 
          className='signin_form'
          onSubmit={onsubmit}
        >
          <h2>Sign into your Webapp account</h2>
          <div className='fields'>
            <div className='field text_field username'>
              <label htmlFor="email">Email</label>
              <input
                id="email"
                type="text"
                value={email}
                onChange={email_onchange}
                data-testid="email-input"
              />
            </div>
            <div className='field text_field password'>
              <label htmlFor="password">Password</label>
              <input
                id="password"
                type="password"
                value={password}
                onChange={password_onchange}
                data-testid="password-input"
              />
            </div>
          </div>
          {el_errors}
          <div className='submit'>
            <Link to="/forgot" className="forgot-link">Forgot Password?</Link>
            <button type='submit' disabled={loading}>
              {loading ? "Signing In..." : "Sign In"}
            </button>
          </div>

        </form>
        <div className="dont-have-an-account">
          <span>
            Don't have an account?
          </span>
          <Link to="/signup">Sign up!</Link>
        </div>
      </div>

    </article>
  );
}