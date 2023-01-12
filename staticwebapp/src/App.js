import logo from './logo.svg';
import './App.css';

function App() {
  console.log(process.env);
  return (
    
    <div className="App">
      <header className="App-header">
        <img src={logo} className="App-logo" alt="logo" />
        <p>
          Edit <code>src/App.js</code> and save to reload.
        </p>
        <a
          className="App-link"
          href="https://reactjs.org"
          target="_blank"
          rel="noopener noreferrer"
        >
          {process.env.NODE_ENV}
         
        </a>
        <h1> {process.env.REACT_APP_MY_KEY} - Environemnt</h1>
      </header>
    </div>
  );
}

export default App;
