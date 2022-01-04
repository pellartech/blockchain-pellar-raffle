const csv = require("csv-parser");
const fs = require("fs");
const { config } = require("dotenv");
config();

const { ethers } = require("ethers");
const { includes } = require("lodash");
const RAFFLE_ABI = [
  {
    inputs: [
      { internalType: "uint256", name: "_raffleId", type: "uint256" },
      { internalType: "address[]", name: "_addresses", type: "address[]" },
    ],
    name: "addEntries",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
];
const RAFFLE_ADDRESS = "0x0c4b50D90d7ca9cA53f7dE1718eB9443e539F563"; // need to switch to mainnet here
const RAFFLE_ID = 1
const URL = process.env.POLYGON_FULLNODE_URL; // need to switch to mainnet here
const PRIVATE_KEY = process.env.POLYGON_PRIVATE_KEY;

const readCsv = async () => {
  const results = [];
  return new Promise((resolve, reject) => {
    fs.createReadStream("./dataset/quest.csv")
      .pipe(
        csv({
          mapHeaders: ({ header }) => {
            return header.toLocaleLowerCase().trim().split(" ").join("_");
          },
        })
      )
      .on("data", (data) => {
        results.push(data.public_address);
      })
      .on("error", (err) => {
        reject(err);
      })
      .on("end", () => {
        resolve(results);
      });
  });
};

const main = async () => {
  const raffleId = RAFFLE_ID;
  const raffleEntries = await readCsv();

  if (raffleEntries.length === 0) {
    throw new Error("Addresses are null");
  }
  if (includes(raffleEntries, undefined)) {
    throw new Error("Undefined address")
  }

  const provider = ethers.getDefaultProvider(URL);
  const owner = new ethers.Wallet(PRIVATE_KEY, provider);
  const contract = new ethers.Contract(RAFFLE_ADDRESS, RAFFLE_ABI, owner);

  const txn = await (
    await contract.addEntries(raffleId, raffleEntries, { gasLimit: 7500000 })
  ).wait();
  console.log(Number(txn.gasUsed));
};

main()
  .then()
  .catch((err) => {
    console.log(err);
  });
