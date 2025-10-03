import { useState } from "react";
import { Button } from "./ui/button";
import { LoaderCircleIcon, Wallet2 } from "lucide-react";

const Navbar = () => {
  const [loading, setLoading] = useState(false);
  const connectWallet = async () => {
    setLoading(true);
  };
  return (
    <div className="px-12 py-4 w-full h-fit flex justify-between items-center">
      <div>
        <h2 className="text-3xl font-bold text-neutral-800 pl-10">PP</h2>
      </div>
      <div>
        <Button onClick={connectWallet} className="cursor-pointer">
          {loading ? <LoaderCircleIcon className="animate-spin" /> : <Wallet2 />}
          Connect wallet
        </Button>
      </div>
    </div>
  );
};

export default Navbar;
