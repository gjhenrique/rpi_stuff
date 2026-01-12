// Example/default ACLs for unrestricted connections.
{
	// Declare static groups of users. Use autogroups for all users or users with a specific role.
	// "groups": {
	//   "group:example": ["alice@example.com", "bob@example.com"],
	// },

	// Define the tags which can be applied to devices and by which users.
	// "tagOwners": {
	//   "tag:example": ["autogroup:admin"],
	// },

	// Define access control lists for users, groups, autogroups, tags,
	// Tailscale IP addresses, and subnet ranges.
	"acls": [
		// Allow all connections.
		// Comment this section out if you want to define specific restrictions.
		{
			"action": "accept",
			"src":    ["group:gui"],

			"dst": [
				"tag:gui-torrent:*",
				"tag:gui-subnet-router:*",

				"192.168.178.96/32:2200",

				"192.168.178.96/32:53",
				"192.168.178.96/32:80",
				"192.168.178.96/32:9120",
				"192.168.178.96/32:443",
			],
		},
		{
			"action": "accept",
			"src":    ["group:pedro"],

			"dst": [
				"tag:pedro-torrent:*",
				"tag:pedro-share:*",
				"tag:pedro-syncthing:*",
				"tag:pedro-emby:*",
				"tag:pedro-plex:*",
				"tag:pedro-observability:*",
				"tag:pedro-actual:*",
				"tag:pedro-paperless:*",
				"tag:tanaka-subnet-router:*",
				"tag:tanaka-adguard:*",
				"tag:tanaka-emby:*",
				"tag:tanaka-samba:*",
			],
		},

		// Allow users in "group:example" to access "tag:example", but only from
		// devices that are running macOS and have enabled Tailscale client auto-updating.
		// {"action": "accept", "src": ["group:example"], "dst": ["tag:example:*"], "srcPosture":["posture:autoUpdateMac"]},
	],

	// Define postures that will be applied to all rules without any specific
	// srcPosture definition.
	// "defaultSrcPosture": [
	//      "posture:anyMac",
	// ],

	// Define device posture rules requiring devices to meet
	// certain criteria to access parts of your system.
	// "postures": {
	//      // Require devices running macOS, a stable Tailscale
	//      // version and auto update enabled for Tailscale.
	//  "posture:autoUpdateMac": [
	//      "node:os == 'macos'",
	//      "node:tsReleaseTrack == 'stable'",
	//      "node:tsAutoUpdate",
	//  ],
	//      // Require devices running macOS and a stable
	//      // Tailscale version.
	//  "posture:anyMac": [
	//      "node:os == 'macos'",
	//      "node:tsReleaseTrack == 'stable'",
	//  ],
	// },

	// Define users and devices that can use Tailscale SSH.
	"ssh": [
		{
			"action": "check",
			"dst":    ["autogroup:self"],
			"src":    ["autogroup:member"],
			"users":  ["autogroup:nonroot", "root"],
		},
		{
			"action": "accept",

			"dst": [
				"tag:pedro-torrent",
				"tag:pedro-share",
				"tag:pedro-syncthing",
				"tag:pedro-observability",
				"tag:pedro-actual",
				"tag:pedro-paperless",
				"tag:tanaka-subnet-router",
				"tag:tanaka-adguard",
				"tag:tanaka-emby",
				"tag:tanaka-samba",
			],

			"src":   ["group:pedro"],
			"users": ["autogroup:nonroot", "root"],
		},
	],

	"tagOwners": {
		"tag:gui-subnet-router": ["group:gui"],
		"tag:gui-torrent":       ["group:gui"],

		"tag:pedro-mgmt":          ["group:pedro"],
		"tag:pedro-torrent":       ["tag:pedro-mgmt"],
		"tag:pedro-syncthing":     ["tag:pedro-mgmt"],
		"tag:pedro-share":         ["tag:pedro-mgmt"],
		"tag:pedro-emby":          ["tag:pedro-mgmt"],
		"tag:pedro-observability": ["tag:pedro-mgmt"],
		"tag:pedro-plex":          ["tag:pedro-mgmt"],
		"tag:pedro-actual":        ["tag:pedro-mgmt"],
		"tag:pedro-paperless":     ["tag:pedro-mgmt"],

		"tag:tanaka-mgmt":          ["group:pedro"],
		"tag:tanaka-subnet-router": ["tag:tanaka-mgmt"],
		"tag:tanaka-adguard":       ["tag:tanaka-mgmt"],
		"tag:tanaka-emby":          ["tag:tanaka-mgmt"],
		"tag:tanaka-samba":         ["tag:tanaka-mgmt"],
	},

	"groups": {
		"group:gui":   ["gjhenrique@github", "ph.sakamoto@gmail.com"],
		"group:pedro": ["pedro.stanaka@gmail.com", "carolinamassae@gmail.com"],
	},

	"nodeAttrs": [
		{
			"target": ["100.100.17.93"],
			"attr":   ["mullvad"],
		},
		{
			"target": ["100.82.95.65"],
			"attr":   ["mullvad"],
		},
		{
			"target": ["100.84.236.52"],
			"attr":   ["mullvad"],
		},
		{
			"target": ["100.121.203.124"],
			"attr":   ["mullvad"],
		},
		{
			"target": ["autogroup:member", "tag:gui-subnet-router"],
			"attr":   ["funnel"],
		},
		{"target": ["100.86.172.76"], "attr": ["mullvad"]},
		{"target": ["100.68.99.64"], "attr": ["mullvad"]},
		{"target": ["100.74.216.15"], "attr": ["mullvad"]},
	],

	"autoApprovers": {
		"routes": {
			"192.168.178.0/24": ["tag:gui-subnet-router"],
			"192.168.1.0/24":   ["tag:tanaka-subnet-router"],
		},
	},

	// Test access rules every time they're saved.
	// "tests": [
	//   {
	//       "src": "alice@example.com",
	//       "accept": ["tag:example"],
	//       "deny": ["100.101.102.103:443"],
	//   },
	// ],
}
