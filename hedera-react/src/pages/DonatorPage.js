import React, { useState } from "react";
import { ethers } from "ethers";
import ctcData from "../artifacts/Main.json";


const ctcAddr = "0x4f6C897a5e2dC9DE2Abb44B644c4B40dc5637B22";

const provider = new ethers.providers.Web3Provider(window.ethereum);
const signer = provider.getSigner();
const ctc = new ethers.Contract(ctcAddr, ctcData.abi, signer);

const DonatorPage = () => {

    const [donationAmt, setDonationAmt] = useState();
    const [name, setName] = useState();
    const [uri, setUri] = useState();

    const donate = async (amt, _name, _uri) => {
        const formattedAmt = ethers.utils.parseUnits(donationAmt, "ether");
        const txn = await ctc.donate(_name, _uri, { value: formattedAmt });
        const receipt = await txn.wait();
        console.log(receipt)
    }

    return (
        <div style={{ display: "flex", flexDirection: "column", alignItems: "center" }}>
            <h1>Donator Page</h1>
            <input onChange={(e) => { setDonationAmt(e.target.value) }}
                type='text' placeholder="Donation Amount" />
            <input onChange={(e) => { setName(e.target.value) }}
                type='text' placeholder="Name" />
            <input onChange={(e) => { setUri(e.target.value) }}
                type='text' placeholder="Uri" />
            <button onClick={() => donate(donationAmt, name, uri)}>Donate</button>
        </div>
    )
}

export default DonatorPage;