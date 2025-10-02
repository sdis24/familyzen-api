const el = document.getElementById("status");
fetch("http://localhost:8000/health")
  .then(r => r.json())
  .then(j => { el.textContent = j.ok ? "API OK ✅" : "API NOT OK ❌"; })
  .catch(e => { el.textContent = "API error: " + e; });
