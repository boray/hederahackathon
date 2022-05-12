import React, { useEffect } from "react";
import { ethers } from "ethers";
import { Routes, Route, Link } from "react-router-dom";
import HomePage from "./pages/HomePage";
import ValidatorPage from "./pages/ValidatorPage";
import StudentPage from "./pages/StudentPage";
import DonatorPage from "./pages/DonatorPage";
import './App.css';

function App() {
  useEffect(() => {

  }, []);
  return (
    <div>
      <Routes>
        <Route path="/" element={<HomePage />} />
        <Route path="validator" element={<ValidatorPage />} />
        <Route path="student" element={<StudentPage />} />
        <Route path="donator" element={<DonatorPage />} />
      </Routes>
    </div>
  );
}

export default App;
