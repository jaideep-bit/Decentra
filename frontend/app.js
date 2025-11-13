// Connect to MetaMask + Contract
const connectButton = document.getElementById("connectButton");
const walletAddress = document.getElementById("walletAddress");
const createDocBtn = document.getElementById("createDocBtn");
const checkDocBtn = document.getElementById("checkDocBtn");

let provider;
let signer;
let contract;

// Replace with your contract address & ABI
const contractAddress = "0xe6DEb38A1960A455098a2D1A2163F56e30b02F6c";
const contractABI = [
  // Example ABI - update with your actual ABI
  "function createDocument(string memory _hash) public",
  "function getDocumentStatus(string memory _hash) public view returns (bool, address)"
];

// Connect Wallet
async function connectWallet() {
  if (window.ethereum) {
    provider = new ethers.providers.Web3Provider(window.ethereum);
    await provider.send("eth_requestAccounts", []);
    signer = provider.getSigner();
    const address = await signer.getAddress();
    walletAddress.innerText = `Connected: ${address}`;
    contract = new ethers.Contract(contractAddress, contractABI, signer);
  } else {
    alert("MetaMask not detected!");
  }
}

// Create Document
async function createDocument() {
  const hash = document.getElementById("docHash").value;
  if (!hash) return alert("Enter a document hash");

  try {
    const tx = await contract.createDocument(hash);
    await tx.wait();
    alert("✅ Document created successfully!");
  } catch (error) {
    console.error(error);
    alert("❌ Transaction failed!");
  }
}

// Check Document Status
async function checkDocument() {
  const hash = document.getElementById("checkHash").value;
  if (!hash) return alert("Enter a document hash");

  try {
    const [exists, creator] = await contract.getDocumentStatus(hash);
    const statusText = exists
      ? `✅ Document exists. Created by: ${creator}`
      : "❌ Document not found.";
    document.getElementById("docStatus").innerText = statusText;
  } catch (error) {
    console.error(error);
    alert("Error fetching document status.");
  }
}

// Event Listeners
connectButton.addEventListener("click", connectWallet);
createDocBtn.addEventListener("click", createDocument);
checkDocBtn.addEventListener("click", checkDocument);
