import React, { useEffect, useState } from "react";
import { createRoot } from "react-dom/client";
import axios from "axios";

console.log("DEBUG VITE_API_URL =", import.meta.env.VITE_API_URL); const API = (import.meta.env.VITE_API_URL || "http://localhost:8000").replace(/\/$/,"");

function App() {
  const [health, setHealth] = useState("Checking APIÃ¢â‚¬Â¦");
  const [fcm, setFcm] = useState(null);
  const [plan, setPlan] = useState(null);
  const [error, setError] = useState(null);

  useEffect(() => {
    axios.get(`${API}/health`)
      .then(r => setHealth(r.data?.ok ? "API OK Ã¢Å“â€¦" : "API NOT OK Ã¢ÂÅ’"))
      .catch(e => setHealth("API error: " + e));

    // Envoi dÃ¢â‚¬â„¢un token FCM factice (dÃƒÂ©mo)
    axios.post(`${API}/users/me/fcm-token`, { token: "TEST_123" })
      .then(r => setFcm(r.data))
      .catch(e => setError("FCM error: " + e.message));

    // Appel assistant mock
    axios.post(`${API}/families/1/assistant/suggest-plan`, {})
      .then(r => setPlan(r.data))
      .catch(e => setError("Assistant error: " + e.message));
  }, []);

  return (
    <main style={{fontFamily:"system-ui, Segoe UI, Roboto", padding: 24, lineHeight: 1.5}}>
      <h1>FamilyZen Ã¢â‚¬â€œ React Dev</h1>
      <p>{health}</p>
      {fcm && <pre><b>FCM:</b> {JSON.stringify(fcm, null, 2)}</pre>}
      {plan && <pre><b>Assistant:</b> {JSON.stringify(plan, null, 2)}</pre>}
      {error && <p style={{color:"crimson"}}>{error}</p>}
      <small>API: {API}</small>
    </main>
  );
}

createRoot(document.getElementById("root")).render(<App />);
