import { ethers } from "ethers";
import { Raffle__factory, type Raffle } from "../../typechain-types";

let signer: ethers.Signer;
let contract: Raffle;

export const connectWallet = async () => {
  const provider = new ethers.BrowserProvider(window.ethereum!);
  await provider.send("eth_requestAccounts", []); // ✅ correct method name
  signer = await provider.getSigner();

  contract = Raffle__factory.connect(
    import.meta.env.VITE_SEPOLIA_CONTRACT_ADDRESS!, // ✅ correct env var usage
    signer
  );

  console.log("Wallet connected:", await signer.getAddress());
};

export const enterRaffle = async (value: string) => {
  if (!contract) throw new Error("Connect wallet first");

  try {
    const tx = await contract.enterRaffle({
      value: ethers.parseEther(value), // ✅ if function is payable
    });
    const receipt = await tx.wait(); // ✅ works in ethers v6
    console.log("Transaction mined:", receipt!.hash);
  } catch (error) {
    console.error("Raffle entry failed:", error);
  }
};
