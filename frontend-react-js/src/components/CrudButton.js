import './PostButton.css';

export default function PostButton(props) {
  const pop_activities_form = (event) => {
    props.setPopped(true);
  }

  return (
    <button onClick={pop_activities_form} className='post' href="#">Post</button>
  );
}