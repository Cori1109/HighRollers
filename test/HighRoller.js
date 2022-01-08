const HighRoller = artifacts.require("HighRoller");

contract("HighRoller", (accounts) => {
  it("Check highroller", () =>
    HighRoller.deployed()
      .then((instance) => instance.openBounty.call())
      .then((instance) =>
        instance.bountyList(0x1c15576615a44fd88504f4851315748cf9275a19).call()
      )
      .then((selected) => {
        console.log("===", selected);
      }));
});
