import React, { useEffect, useState } from "react";
import { ethers } from "ethers";
import ctcData from "../artifacts/Main.json";
import Document from "../models/Document";

const ctcAddr = "0x4f6C897a5e2dC9DE2Abb44B644c4B40dc5637B22";

const provider = new ethers.providers.Web3Provider(window.ethereum);
const signer = provider.getSigner();
const ctc = new ethers.Contract(ctcAddr, ctcData.abi, signer);

const convertToString = async (bytes32) => {
    return await ethers.utils.parseBytes32String(bytes32);
}

function timeConverter(UNIX_timestamp) {
    const a = new Date(UNIX_timestamp * 1000);
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const year = a.getFullYear();
    const month = months[a.getMonth()];
    const date = a.getDate();
    const time = date + ' ' + month + ' ' + year + ' ';
    const time2 = a.toLocaleTimeString("en-US");
    const fullDate = time.concat(time2);
    return fullDate;
}

const validateStudent = async (_studentId) => {
    const txn = await ctc.validateStudentPeriodAllowance(_studentId);
    const receipt = await txn.wait();
    console.log(receipt);
}

const ValidatorPage = () => {

    const [studentsNo, setStudentsNo] = useState(0);
    const [studentToDocuments, setStudentToDocuments] = useState({}); // studentId -> Document

    useEffect(() => {

        const getStudentsNo = async () => {
            const res = await ctc.getNoOfStudents();
            setStudentsNo(res.toNumber());
        }

        const getAllDocuments = async (_studentId) => {
            const res = await ctc.getAllDocuments(_studentId);
            return res;
        }

        const getDocument = async (_studentId, _name) => {
            const res = await ctc.getDocument(_studentId, _name);
            return res;
        }

        const listAllStudents = async () => {
            let newStToDocs = {};
            for (let i = 0; i < studentsNo; i++) {
                const names = await getAllDocuments(i);
                const len = names.length;
                const documents = [];
                for (let j = 0; j < len; j++) {
                    const doc = await getDocument(i, names[j]);
                    const name = await convertToString(names[j]); 
                    const documentHash = await convertToString(doc[1]);
                    const timestamp = doc[2].toNumber();
                    const uri = doc[0];
                    const docObj = new Document(name, uri, documentHash, timestamp);
                    documents[j] = docObj;
                }
                newStToDocs[i] = documents;
            }
            setStudentToDocuments(newStToDocs);
        }

        getStudentsNo();
        listAllStudents();

    }, [studentsNo]);

    const keys = Object.keys(studentToDocuments);

    return (
        <div style={{ display: "flex", flexDirection: "column", alignItems: "center" }}>
            <h1>Validator Page</h1>
            {keys.length > 0 ? (keys.map((k, idx) => {
                const docs = studentToDocuments[k];
                return (
                    <div key={idx}>
                        <h3>Student #{idx}</h3>
                        {docs.map((doc, i) => {
                            return (
                                <div key={i}>
                                    <h3>Document #{i + 1}</h3>
                                    <ul>
                                        <li>Document name: {doc.name}</li>
                                        <li>URL: {doc.uri}</li>
                                        <li>Document Hash: {doc.documentHash}</li>
                                        <li>Last Edited Date: {timeConverter(doc.timestamp)}</li>
                                    </ul>
                                </div>)
                        })}
                        <button onClick={() => { validateStudent(idx) }}>
                            Validate Student #{idx}
                        </button>
                        <hr />
                    </div>
                )
            })) : <h1>Loading...</h1>}
        </div>
    )
}

export default ValidatorPage;