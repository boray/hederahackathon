import React, { useState, useEffect } from "react";
import { useSearchParams } from "react-router-dom";
import { ethers } from "ethers";
import ctcData from "../artifacts/Main.json";

const ctcAddr = "0x4f6C897a5e2dC9DE2Abb44B644c4B40dc5637B22";

const provider = new ethers.providers.Web3Provider(window.ethereum);
const signer = provider.getSigner();
const ctc = new ethers.Contract(ctcAddr, ctcData.abi, signer);

const StudentPage = () => {
    

    const [docName, setDocName] = useState();
    const [docUri, setDocUri] = useState();
    const [docHash, setDocHash] = useState();
    const [claimable, setClaimable] = useState();
    const [id, setId] = useState();

    useEffect(() => {
        const getId = async () => {
            const res = await ctc.getIdFromAddress();
            setId(res.toNumber());
        }
        const getClaimable = async () => {
            const res = await ctc.getClaimableAmount();
            console.log(res);
            const formattedClaimable = ethers.utils.formatEther(res)
            setClaimable(formattedClaimable);
        }
        getId();
        getClaimable();
    }, [])

    const uploadDocument = async () => {
        const name = ethers.utils.formatBytes32String(docName);
        const hash = ethers.utils.formatBytes32String(docHash)
        const txn = await ctc.setDocument(id, name, docUri, hash);
        const receipt = await txn.wait();
        console.log(receipt);
    }

    const claimDonation = async () => {
        const txn = await ctc.withdrawAsStudent();
        const receipt = await txn.wait();
        console.log(receipt);
    }

    return (
        <div style={{ display: "flex", flexDirection: "column", alignItems: "center" }}>
            <h1>Student Page</h1>
            <h3>Student #{id}</h3>
            <div>
                <h2>Upload File To Be Inspected By Validators</h2>
                <div>
                    <input onChange={(e) => setDocName(e.target.value)}
                        type="text" placeholder="Document Name" />
                    <input onChange={(e) => setDocUri(e.target.value)}
                        type="text" placeholder="Document Uri" />
                    <input onChange={(e) => setDocHash(e.target.value)}
                        type="text" placeholder="Document Hash" />
                    <button onClick={uploadDocument}>Upload Document</button>
                </div>
            </div>
            <div>
                <h2>Claim Donation</h2>
                <div style={{ display: "flex", justifyContent: "center", alignItems: "center" }}>
                    <h3>Claimable Amount: {claimable ?? 0} ETH</h3>
                    <button onClick={claimDonation}>Claim</button>
                </div>

            </div>
        </div>
    )
}

export default StudentPage;