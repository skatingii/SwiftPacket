import { defineConfig } from "vitepress"

export default defineConfig({
	title: "SwiftPacket",
	description: "Typed, batched networking for Roblox",
	base: "/SwiftPacket/",

	themeConfig: {
		nav: [
			{ text: "Crash course", link: "/tut/crash-course/1-introduction" },
			{ text: "API", link: "/api/swiftpacket" },
		],

		sidebar: {
			"/tut/": [
				{
					text: "Crash course",
					items: [
						{ text: "Introduction", link: "/tut/crash-course/1-introduction" },
						{ text: "Installation", link: "/tut/crash-course/2-installation" },
						{ text: "Defining packets", link: "/tut/crash-course/3-packets" },
						{ text: "Events", link: "/tut/crash-course/4-events" },
						{ text: "Requests", link: "/tut/crash-course/5-requests" },
						{ text: "Types", link: "/tut/crash-course/6-types" },
						{ text: "Security", link: "/tut/crash-course/7-security" },
						{ text: "Migrating from Packet", link: "/tut/crash-course/8-migrating-from-packet" },
					],
				},
			],

			"/api/": [
				{
					text: "API",
					items: [
						{ text: "SwiftPacket", link: "/api/swiftpacket" },
						{ text: "Packet", link: "/api/packet" },
						{ text: "Signal", link: "/api/signal" },
						{ text: "Types", link: "/api/types" },
					],
				},
			],
		},

		socialLinks: [{ icon: "github", link: "https://github.com/skatingii/SwiftPacket" }],
	},
})
