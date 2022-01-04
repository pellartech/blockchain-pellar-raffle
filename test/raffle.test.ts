import { ethers } from 'hardhat'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import chai from 'chai'
import chaiAsPromised from 'chai-as-promised'
import { solidity } from 'ethereum-waffle'
import { map, max, min, uniq } from 'lodash'

import { RaffleContract, RaffleContract__factory } from '../typechain'

chai.use(solidity)
chai.use(chaiAsPromised)
const { expect } = chai

describe('Raffle', () => {
  let accounts: SignerWithAddress[]
  let interactContract: RaffleContract
  let owner: SignerWithAddress, bob: SignerWithAddress, alice: SignerWithAddress

  beforeEach(async () => {
    accounts = await ethers.getSigners()
    owner = accounts[0]
    bob = accounts[1]
    alice = accounts[2]

    const AOFactory = (await ethers.getContractFactory(
      'RaffleContract',
      owner,
    )) as RaffleContract__factory
    interactContract = await AOFactory.deploy()
    await interactContract.deployed()

    expect(interactContract.address).to.properAddress
    // console.log(
    //   'Gas used for deploy: ',
    //   Number((await txn.deployTransaction.wait()).gasUsed),
    // )
  })

  context('Test case for owner rules', () => {
    it('Admin functions should be convert without owner', async () => {
      await expect(
        interactContract.connect(alice).createRandomSeed(0),
      ).revertedWith('Ownable: caller is not the owner')
      await expect(interactContract.connect(alice).withdrawLink()).revertedWith(
        'Ownable: caller is not the owner',
      )
      await expect(interactContract.connect(alice).withdraw()).revertedWith(
        'Ownable: caller is not the owner',
      )
      await expect(
        interactContract.connect(bob).createRaffle(0, 100),
      ).revertedWith('Ownable: caller is not the owner')
      await expect(
        interactContract.connect(bob).addEntries(0, []),
      ).revertedWith('Ownable: caller is not the owner')
      await expect(
        interactContract.connect(bob).setEntries(0, []),
      ).revertedWith('Ownable: caller is not the owner')
      await expect(
        interactContract.connect(bob).drawWinners(0, 100),
      ).revertedWith('Ownable: caller is not the owner')
    })
  })

  context('Test case for createRaffle', () => {
    it('createRaffle should be success', async () => {
      await (await interactContract.connect(owner).createRaffle(0, 1000)).wait()
      const raffle = await interactContract.raffles(0)
      expect(raffle.totalWinners).equal(1000)
      expect(raffle.seeded).equal(false)
      expect(raffle.seedNumber).equal(0)
      const raffleEntries = await interactContract.getRaffleEntries(0, 0, 100)
      expect(raffleEntries.length).equal(0)
      const raffleWinners = await interactContract.getRaffleWinners(0, 0, 100)
      expect(raffleWinners.length).equal(0)
    })

    it('createRaffle should be reverted if already drew winners', () => {})
  })

  context('Test case for drawWinners', () => {
    it('drawWinners should be correct', async () => {
      await (await interactContract.connect(owner).createRaffle(0, 100)).wait()
      const entries = map(accounts, (el) => el.address).slice(0, 100) // 100 elements
      await (await interactContract.connect(owner).addEntries(0, entries)).wait()
      await (
        await interactContract
          .connect(owner)
          .drawWinners(0, 100)
      ).wait()

      expect((await interactContract.raffles(0)).mark).equal(0)
      const raffle = await interactContract.raffles(0)
      expect(raffle.totalWinners).equal(100)
      expect(raffle.mark).equal(0)
      const raffleEntries = await interactContract.getRaffleEntries(0, 0, 100)
      expect(raffleEntries.length).equal(100)
      const raffleWinners = await interactContract.getRaffleWinners(0, 0, 100)
      expect(raffleWinners.length).equal(100)
    })
  })
})
