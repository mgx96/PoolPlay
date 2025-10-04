"use client";
import { useState } from "react";
import { Copy, Loader2, Trophy, Users, Zap } from "lucide-react";
const poolPrize = "5 ether";
const entranceFee = "5$";
const Players = "6 players";
const lastWinener = "0xx0x0x0x0000000000x00000000990000x00";
const PoolThree = () => {
  const [loading, setLoading] = useState(false);
  const [copied, setCopied] = useState(false);

  const handleCopy = () => {
    navigator.clipboard.writeText(lastWinener);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };
  const handleEnterRaffle = async () => {
    console.log("cliekced");
    setLoading(true);
  };
  return (
    <div className="bg-green-600 rounded-2xl p-6 w-64 shadow-lg">
      <div className="flex flex-col items-center mb-6">
        <div className="bg-green-500/30 p-4 rounded-xl mb-4">
          <div className="w-16 h-16 border-4 border-green-300 rounded-lg relative">
            <div className="absolute -top-3 -left-3 w-16 h-16 border-4 border-green-200 rounded-lg"></div>
          </div>
        </div>
        <h2 className="text-white text-2xl font-bold">15 Player Pool</h2>
      </div>

      <div className="bg-white rounded-xl p-4 space-y-3 mb-4">
        <div className="flex justify-between items-center">
          <div className="flex items-center gap-2">
            <Trophy className="w-4 h-4 text-gray-600" />
            <span className="text-sm text-gray-700">Pool Prize</span>
          </div>
          <span className="font-bold text-gray-900">{poolPrize}</span>
        </div>

        <div className="flex justify-between items-center">
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 text-gray-600">💰</div>
            <span className="text-sm text-gray-700">{entranceFee}</span>
          </div>
          <span className="font-bold text-gray-900">0.1ETH</span>
        </div>

        <div className="flex justify-between items-center">
          <div className="flex items-center gap-2">
            <Users className="w-4 h-4 text-gray-600" />
            <span className="text-sm text-gray-700">{Players}</span>
          </div>
          <span className="font-bold text-gray-900">2/5</span>
        </div>

        <div className="flex justify-between items-center">
          <div className="flex items-center gap-2">
            <Zap className="w-4 h-4 text-gray-600" />
            <span className="text-sm text-gray-700">Last Winner</span>
          </div>
          <div className="flex items-center gap-1">
            <span className="font-bold text-gray-900 overflow-clip w-22 overflow-x-hidden">
              {lastWinener}
            </span>
            <Copy
              onClick={() => handleCopy()}
              className={`w-3.5 h-3.5 cursor-pointer ${
                copied ? "text-green-500" : "text-gray-400 hover:text-gray-600"
              }`}
            />
          </div>
        </div>
      </div>

      <button
        onClick={handleEnterRaffle}
        disabled={loading}
        className="w-full bg-teal-800 hover:bg-teal-900 text-white font-semibold py-3 rounded-xl transition-colors flex items-center justify-center gap-2"
      >
        {loading ? <Loader2 className="w-5 h-5 animate-spin" /> : null}
        Enter Raffle
      </button>
    </div>
  );
};

export default PoolThree;
