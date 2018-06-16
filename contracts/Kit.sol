pragma solidity ^0.4.18;

import "@aragon/os/contracts/factory/DAOFactory.sol";
import "@aragon/os/contracts/apm/Repo.sol";
import "@aragon/os/contracts/lib/ens/ENS.sol";
import "@aragon/os/contracts/lib/ens/PublicResolver.sol";
import "@aragon/os/contracts/apm/APMNamehash.sol";

import "aragon-delay/contracts/Delay.sol";
import "@aragon/identity/contracts/Identity.sol";
import "@aragon/permission-manager/contracts/PermissionManager.sol";
import "@aragon/counter/contracts/CounterApp.sol";

contract KitBase is APMNamehash {
	ENS public ens;
    DAOFactory public fac;

    event DeployInstance(address dao);
    event InstalledApp(address appProxy, bytes32 appId);

    function KitBase(DAOFactory _fac, ENS _ens) {
    	ens = _ens;

    	// If no factory is passed, get it from on-chain bare-kit
    	if (address(_fac) == address(0)) {
    		bytes32 bareKit = apmNamehash("bare-kit");
    		fac = KitBase(latestVersionAppBase(bareKit)).fac();
    	} else {
    		fac = _fac;
    	}
    }

	function latestVersionAppBase(bytes32 appId) public view returns (address base) {
        Repo repo = Repo(PublicResolver(ens.resolver(appId)).addr(appId));
        (,base,) = repo.getLatest();

        return base;
    }
}

contract Kit is KitBase {
	//MiniMeTokenFactory tokenFactory;

	uint256 constant PCT = 10 ** 16;
	address constant ANY_ENTITY = address(-1);

  address root;
	bytes32 delayAppId;
	bytes32 identityAppId;
	bytes32 permissionManagerAppId;
	bytes32 counterAppId;


	Delay delayActions;
	Delay delayReset;
	Identity identity;
	Identity factor;
	PermissionManager factorPermissions;
	CounterApp counter;




	function Kit(ENS ens) KitBase(DAOFactory(0), ens) {
		//tokenFactory = new MiniMeTokenFactory();
	}

	function newInstance(address thirdParty) {
		Kernel dao = fac.newDAO(this);
    ACL acl = ACL(dao.acl());
    acl.createPermission(this, dao, dao.APP_MANAGER_ROLE(), this);

    root = msg.sender;
		delayAppId = apmNamehash("delay6");
		identityAppId = apmNamehash("identity");
		permissionManagerAppId = apmNamehash("permission-manager");
		counterAppId = apmNamehash("counter");


		delayActions = Delay(dao.newAppInstance(delayAppId, latestVersionAppBase(delayAppId)));
		delayReset = Delay(dao.newAppInstance(delayAppId, latestVersionAppBase(delayAppId)));
		identity = Identity(dao.newAppInstance(identityAppId, latestVersionAppBase(identityAppId)));
		factor = Identity(dao.newAppInstance(identityAppId, latestVersionAppBase(identityAppId)));
		factorPermissions = PermissionManager(dao.newAppInstance(permissionManagerAppId, latestVersionAppBase(permissionManagerAppId)));
		counter = CounterApp(dao.newAppInstance(counterAppId, latestVersionAppBase(counterAppId)));





		// Permissions
		acl.createPermission(factor, delayActions, delayActions.INITIATE_ROLE(), identity);
		acl.createPermission(factor, delayActions, delayActions.ACTIVATE_ROLE(), identity);
		acl.createPermission(factor, delayActions, delayActions.CANCEL_ROLE(), identity);

		acl.createPermission(thirdParty, delayReset, delayReset.INITIATE_ROLE(), identity);
		acl.createPermission(thirdParty, delayReset, delayReset.ACTIVATE_ROLE(), identity);
		acl.createPermission(thirdParty, delayReset, delayReset.CANCEL_ROLE(), identity);
		acl.createPermission(root, delayReset, delayReset.CANCEL_ROLE(), identity);

		acl.createPermission(delayActions, identity, identity.FORWARD_ROLE(), identity);

		acl.createPermission(root, factor, factor.FORWARD_ROLE(), factorPermissions);

		acl.createPermission(delayReset, factorPermissions, factorPermissions.GRANT_ROLE(), identity);
		acl.createPermission(factor, factorPermissions, factorPermissions.REMOVE_ROLE(), identity);
		acl.createPermission(identity, factorPermissions, factorPermissions.SET_MANAGER_ROLE(), identity);

		acl.createPermission(identity, counter, counter.INCREMENT_ROLE(), identity);
		acl.createPermission(identity, counter, counter.DECREMENT_ROLE(), identity);

		// Initialize

		delayActions.initialize(2);
		delayReset.initialize(2);

		// Clean up permissions
		acl.grantPermission(identity, dao, dao.APP_MANAGER_ROLE());
    acl.revokePermission(this, dao, dao.APP_MANAGER_ROLE());
    acl.setPermissionManager(identity, dao, dao.APP_MANAGER_ROLE());

    acl.grantPermission(identity, acl, acl.CREATE_PERMISSIONS_ROLE());
    acl.revokePermission(this, acl, acl.CREATE_PERMISSIONS_ROLE());
    acl.setPermissionManager(identity, acl, acl.CREATE_PERMISSIONS_ROLE());

    DeployInstance(dao);
	}
}
