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
      { internalType: "uint256", name: "_start", type: "uint256" },
      { internalType: "uint256", name: "_end", type: "uint256" },
    ],
    name: "getRaffleWinners",
    outputs: [
      { internalType: "address[]", name: "_winners", type: "address[]" },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [{ internalType: "uint256", name: "_raffleId", type: "uint256" }],
    name: "getWinnersLength",
    outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
];
const RAFFLE_ADDRESS = "0x0c4b50D90d7ca9cA53f7dE1718eB9443e539F563"; // need to switch to mainnet here
const RAFFLE_ID = 1;
const URL = process.env.POLYGON_FULLNODE_URL; // need to switch to mainnet here

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
  const raffleId = String(
    process.argv.find((el) => el.startsWith("--id"))
  ).split("--id=")[1];

  if (raffleId === "undefined" || !raffleId || isNaN(Number(raffleId))) {
    throw new Error("raffleId is invalid");
  }
  const raffleEntries = await readCsv();

  if (raffleEntries.length === 0) {
    throw new Error("Addresses are null");
  }
  if (includes(raffleEntries, undefined)) {
    throw new Error("Undefined address");
  }

  const provider = ethers.getDefaultProvider(URL);
  const contract = new ethers.Contract(RAFFLE_ADDRESS, RAFFLE_ABI, provider);

  const winners = await contract.getRaffleWinners(Number(raffleId), 0, 1000, { gasLimit: 30000000 });
  fs.writeFileSync(`./output/raffle_${raffleId}_winners.json`, JSON.stringify(winners))
};

main()
  .then()
  .catch((err) => {
    console.log(err);
  });
