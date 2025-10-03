"use client";
import { useState } from "react";
import { Button } from "./ui/button";
import { Clipboard, Coins, GoalIcon, LoaderCircleIcon, PartyPopper, Trophy, Users } from "lucide-react";
const poolPrize = "5 ether";
const entraceFee = "5$";
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
  const handleRaffleEnter = async () => {
    console.log("cliekced");
    setLoading(true);
  };
  return (
    <div className="flex flex-col hover:scale-101 bg-gradient-to-br from-neutral-600 via-neutral-700 to-neutral-800 items-center px-3 space-y-5 w-80 py-3 relative border-2 hover:border-cyan-300 rounded-3xl">
      <div className="object-cover items-center abosolute rounded-2xl">
        <img src="poolOne.jpg" className="rounded-2xl" />
      </div>
      <h1 className="text-3xl text-transparent bg-clip-text bg-gradient-to-r from-blue-600 to-purple-600 h-10 flex items-center justify-center gap-2 font-extrabold  tracking-tight bg-neutral-500 w-full rounded-md shadow-sm">
        <span className="text-yellow-500 font-black">25 </span>Player Pool
      </h1>
      <div className="flex flex-col w-full space-y-3 bg-white rounded-lg shadow-md hover:shadow-lg transition-shadow duration-300">
        {/* Pool Prize */}
        <div className="flex items-center justify-between px-3 ">
          <div className="flex items-center gap-2">
            <Trophy className="size-5 text-amber-500" />
            <span className="font-semibold shine-text">Pool Prize</span>
          </div>
          <span className="text-neutral-800 font-bold">{poolPrize}</span>
        </div>

        {/* Entrance Fee */}
        <div className="flex items-center justify-between px-3">
          <div className="flex items-center gap-2">
            <GoalIcon className="size-5 text-blue-500" />
            <span className="font-semibold shine-text">Entrance Fee</span>
          </div>
          <span className="text-neutral-800 font-bold">{entraceFee}</span>
        </div>

        {/* Players */}
        <div className="flex items-center justify-between px-3">
          <div className="flex items-center gap-2">
            <Users className="size-5 text-green-500" />
            <span className="font-medium shine-text">Players</span>
          </div>
          <span className="text-neutral-800 font-bold">{Players}</span>
        </div>

        {/* Last Winner with Copy Button */}
        <div className="flex items-center justify-between px-3">
          <div className="flex items-center gap-2">
            <PartyPopper className="size-5 text-purple-500" />
            <span className="font-semibold shine-text">Last Winner</span>
          </div>
          <div className="flex items-center gap-2">
            <span className="text-neutral-800 font-bold  overflow-clip w-22 overflow-x-hidden m3-1">
              {lastWinener}
            </span>
            <Clipboard
              onClick={handleCopy}
              className={`size-4 cursor-pointer m-0 p-0   ${
                copied
                  ? "text-neutral-400 bg-transparent"
                  : "text-neutral-800 bg-transparent"
              }`}
            />
          </div>
        </div>
      </div>
      <Button
        className="flex items-center cursor-pointer justify-center w-full rounded-b-2xl"
        onClick={handleRaffleEnter}
      >
        {loading ? <LoaderCircleIcon className="animate-spin" /> : <Coins />}
        Enter Raffle
      </Button>
    </div>
  );
};

export default PoolThree;
