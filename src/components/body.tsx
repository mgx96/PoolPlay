import Footer from "./Footer"
import PollOne from "./PollOne"
import PoolThree from "./PoolThree"
import PoolTwo from "./PoolTwo"

const Body = () => {
  return (
    <div className="flex flex-col gap-20 items-center">
        <h1 className="text-4xl font-extrabold px-12">Raffle Contract</h1>
        <div className="flex flex-col md:flex-row justify-center items-center md:justify-around w-full">
            <PollOne/>
            <PoolTwo/>
            <PoolThree/>
        </div>
        <Footer/>
    </div>
  )
}

export default Body