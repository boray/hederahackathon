import React from "react";
import { useSearchParams } from "react-router-dom";

const StudentPage = () => {
    let [searchParams, setSearchParams] = useSearchParams();
    const id = searchParams.get("id");

    const uploadDocument = async () => {

    }

    const claimDonation = async () => {

    }

    return (
        <div style={{ display: "flex", flexDirection: "column", alignItems: "center" }}>
            <h1>Student Page</h1>
            <h3>Student #{id}</h3>
            <div>
                <h2>Upload File To Be Inspected By Validators</h2>
                <input type="text" placeholder="Document Uri" />
                <button onClick={uploadDocument}>Upload</button>
            </div>
            <div>
                <h2>Claim Donation</h2>
                <div style={{display: "flex", justifyContent: "center", alignItems: "center"}}>
                    <h3>Claimable Amount: xx$</h3>
                    <button onClick={claimDonation}>Claim</button>
                </div>

            </div>
        </div>
    )
}

export default StudentPage;