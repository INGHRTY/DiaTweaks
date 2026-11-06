#import <Foundation/Foundation.h>

// English to Chinese for Dia's and DiaTweaks' own interface text. Keys match exactly; anything not listed stays English.
// Keep the Chinese side unique: turning the patch off looks a Chinese string up to put its English back.
NSDictionary<NSString *, NSString *> *DPChineseStrings(void) {
    static NSDictionary<NSString *, NSString *> *strings;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        strings = @{
            // Dia's Settings sections
            @"General" : @"通用",
            @"Appearance" : @"外观",
            @"Privacy" : @"隐私",
            @"Profiles" : @"配置文件",
            @"Sync" : @"同步",
            @"Account" : @"账户",
            @"Billing" : @"账单",
            @"Advanced" : @"高级",
            @"Advanced…" : @"高级…",
            @"Keyboard Shortcuts" : @"键盘快捷键",
            @"Shortcuts" : @"快捷键",
            @"Patches" : @"补丁",
            @"Updates" : @"更新",
            @"Software Update" : @"软件更新",
            @"Passwords" : @"密码",
            @"Links" : @"链接",
            @"Language" : @"语言",
            @"Other" : @"其他",

            // DiaTweaks' sections in Settings
            @"Page" : @"页面",
            @"Toolbar" : @"工具栏",
            @"Sidebar & Tab Bar" : @"侧边栏与标签栏",
            @"Tabs" : @"标签页",
            @"Command Bar" : @"命令栏",
            @"New Tab Page" : @"新标签页",
            @"Window" : @"窗口",

            // Dia's Settings pages
            @"Name" : @"名称",
            @"Email" : @"电子邮件",
            @"More account options" : @"更多账户选项",
            @"Manage Atlassian Account" : @"管理 Atlassian 账户",
            @"Upgrade Account" : @"升级账户",
            @"View Plans" : @"查看方案",
            @"Morning Brief" : @"每日简报",
            @"Receive a daily personalized summary" : @"每天接收个性化摘要",
            @"Profile for Morning Brief" : @"每日简报的配置文件",
            @"Morning Brief needs certain connected apps to run." : @"每日简报需要连接相应应用才能运行。",
            @"Sync your Profiles, Bookmarks, Pinned Tabs, Groups, and Settings across devices. All data is end-to-end encrypted." :
                @"在各设备间同步你的配置文件、书签、固定标签页、标签组和设置。所有数据均经过端到端加密。",
            @"Connect Another Device…" : @"连接另一台设备…",
            @"Dia works best as your default browser" : @"把 Dia 设为默认浏览器体验最佳",
            @"Set Dia as Default" : @"将 Dia 设为默认浏览器",
            @"Restore…" : @"还原…",
            @"Restore the original Dia without patches." : @"还原未经补丁的原始 Dia。",
            @"Ready to install" : @"可以安装",
            @"No Results" : @"无结果",
            @"Search" : @"搜索",
            @"DiaPatches is unofficial and not affiliated with The Browser Company." :
                @"DiaPatches 是非官方项目，与 The Browser Company 无关。",

            // Dia's Settings pages, account and sync
            @"Settings" : @"设置",
            @"Connect Another Device" : @"连接另一台设备",
            @"Set Up Without Another Device" : @"不借助其他设备设置",
            @"Enter Recovery Phrase" : @"输入恢复短语",
            @"Connect with Recovery Phrase" : @"使用恢复短语连接",
            @"Save Recovery Kit" : @"保存恢复工具包",
            @"Save Your Recovery Kit" : @"保存你的恢复工具包",
            @"Copy Recovery Code" : @"复制恢复代码",
            @"Delete My Sync Data" : @"删除我的同步数据",
            @"I understand this cannot be undone" : @"我明白此操作无法撤销",
            @"Stop Syncing This Device?" : @"停止同步此设备？",
            @"Delete Sync Data?" : @"删除同步数据？",
            @"Your organization has disabled sync." : @"你的组织已禁用同步。",
            @"not syncing" : @"未同步",
            @"updated just now" : @"刚刚更新",
            @"Delete Account" : @"删除账户",
            @"Delete Profile" : @"删除配置文件",

            // Dia's Settings pages, advanced and apps
            @"Your organization manages this setting" : @"此设置由你的组织管理",
            @"This change will take effect after the next app update." : @"此更改将在下次应用更新后生效。",
            @"Warn before closing last tab in a Profile" : @"关闭配置文件的最后一个标签页前警告",
            @"Warn before quitting" : @"退出前警告",
            @"When quitting" : @"退出时",
            @"Manage Link Rules" : @"管理链接规则",
            @"Play chat sounds" : @"播放对话声音",
            @"Play daily report sounds" : @"播放每日简报声音",
            @"Address bar routing" : @"地址栏路由",
            @"Automatically update Dia" : @"自动更新 Dia",
            @"Advanced Settings" : @"高级设置",
            @"Unavailable due to organization settings" : @"因组织设置而不可用",
            @"Connection warning" : @"连接警告",
            @"Connection error" : @"连接错误",
            @"Connected" : @"已连接",
            @"MCP not enabled" : @"未启用 MCP",
            @"Connect to this app's MCP server to use more advanced tools and actions" : @"连接此应用的 MCP 服务器，以使用更高级的工具和操作",
            @"No matching apps" : @"没有匹配的应用",
            @"Recommended apps" : @"推荐的应用",
            @"Based on your browsing history" : @"基于你的浏览历史",
            @"Turn On Advanced Chat" : @"开启高级对话",
            @"Connect your apps to let Dia help you with your work" : @"连接你的应用，让 Dia 帮你处理工作",

            // Dia's Settings pages, billing and privacy
            @"Annual billing cadence" : @"按年计费",
            @"Monthly billing cadence" : @"按月计费",
            @"No billing information available." : @"暂无账单信息。",
            @"Renew your plan?" : @"续订套餐？",
            @"Cancel downgrade" : @"取消降级",
            @"Turn Off Ad Blocker?" : @"关闭广告拦截器？",
            @"Content blocking" : @"内容拦截",
            @"Block cookie banners" : @"拦截 Cookie 横幅",
            @"Advanced Ad Block Settings" : @"高级广告拦截设置",
            @"Share content data to help improve Dia" : @"分享内容数据以帮助改进 Dia",
            @"This data will not be tied to your profile" : @"这些数据不会关联到你的配置文件",
            @"Your organization has turned off this setting" : @"你的组织已关闭此设置",
            @"Adjust theme intensity" : @"调整主题强度",
            @"Pick the theme color and layout that feel right for you." : @"挑选适合你的主题色和布局。",
            @"Light" : @"浅色",
            @"Dark" : @"深色",
            @"Automatic" : @"自动",

            // Dialogs and buttons
            @"Cancel" : @"取消",
            @"Done" : @"完成",
            @"Continue" : @"继续",
            @"Save" : @"保存",
            @"Add" : @"添加",
            @"Remove" : @"移除",
            @"Something went wrong. Please try again." : @"出了点问题，请重试。",
            @"Check your connection and try again." : @"检查网络连接，然后重试。",
            @"What went wrong?" : @"哪里出了问题？",
            @"Connection report" : @"连接报告",
            @"Preparing report" : @"正在准备报告",
            @"Tell us what you expected and what happened instead." : @"告诉我们你期望的结果，以及实际发生了什么。",

            // Dia's window
            @"New Tab" : @"新建标签页",
            @"Chats" : @"对话列表",
            @"Chat" : @"对话",
            @"Skills" : @"技能",
            @"Share" : @"分享",
            @"More" : @"更多",
            @"Back" : @"返回",
            @"Close" : @"关闭",
            @"Close tab" : @"关闭标签页",
            @"Delete chat" : @"删除对话",
            @"Recent tabs" : @"最近标签页",
            @"Open in New Tab" : @"在新标签页中打开",
            @"Open pop-up window" : @"打开弹出窗口",
            @"Split tabs" : @"拆分标签页",
            @"Toggle sidebar" : @"切换侧边栏",
            @"Go back" : @"后退",
            @"Go forward" : @"前进",
            @"Reload this page" : @"重新加载此页面",
            @"Site menu" : @"站点菜单",
            @"Chat with this tab" : @"与此标签页对话",
            @"Personalization" : @"个性化",
            @"Personalization on for new chats" : @"新对话已启用个性化",
            @"Export Logs" : @"导出日志",
            @"Export the agent context folder for this session to Downloads" : @"把本次会话的 agent 上下文文件夹导出到下载目录",
            @"Bookmark this page" : @"收藏此页面",
            @"Included in AI history search" : @"已纳入 AI 历史搜索",
            @"Apps" : @"应用",

            // Dia's menus
            @"File" : @"文件",
            @"Edit" : @"编辑",
            @"View" : @"显示",
            @"History" : @"历史记录",
            @"Bookmarks" : @"书签",
            @"Extensions" : @"扩展",
            @"Help" : @"帮助",
            @"Services" : @"服务",

            // The app menu
            @"About Dia" : @"关于 Dia",
            @"Check for Updates" : @"检查更新",
            @"Check for Updates…" : @"检查更新…",
            @"Invite to Dia" : @"邀请使用 Dia",
            @"Better Browser, Free Plan" : @"更好的浏览器，免费套餐",
            @"Upgrade Plan…" : @"升级套餐…",
            @"Settings…" : @"设置…",
            @"Set as Default Browser" : @"设为默认浏览器",
            @"Personalize Dia" : @"个性化 Dia",
            @"Import from Another Browser…" : @"从其他浏览器导入…",
            @"Hide Dia" : @"隐藏 Dia",
            @"Hide Others" : @"隐藏其他",
            @"Show All" : @"全部显示",
            @"Sign In…" : @"登录…",
            @"Sign Out" : @"退出登录",
            @"Quit Dia" : @"退出 Dia",
            @"Quit Sandbox" : @"退出沙盒",

            // File
            @"New Tab in Group" : @"在标签组中新建标签页",
            @"New Window" : @"新建窗口",
            @"New Incognito Window" : @"新建无痕窗口",
            @"Chat…" : @"对话…",
            @"New Chat" : @"新建对话",
            @"Focus Chat" : @"聚焦对话",
            @"Send Chat Prompt Now" : @"立即发送对话提示",
            @"Open Daily Brief" : @"打开每日简报",
            @"Open Command Bar" : @"打开命令栏",
            @"Close Window" : @"关闭窗口",
            @"Close Tab" : @"关闭标签页",
            @"Close All Tabs" : @"关闭所有标签页",
            @"Clean Up Tabs" : @"清理标签页",
            @"Share…" : @"分享…",
            @"Print…" : @"打印…",

            // Edit
            @"Undo" : @"撤销",
            @"Redo" : @"重做",
            @"Cut" : @"剪切",
            @"Copy" : @"复制",
            @"Copy URL" : @"复制网址",
            @"Copy URL as Markdown" : @"以 Markdown 复制网址",
            @"Paste" : @"粘贴",
            @"Paste and Match Style" : @"粘贴并匹配样式",
            @"Delete" : @"删除",
            @"Select All" : @"全选",
            @"Find" : @"查找",
            @"Spelling and Grammar" : @"拼写和语法",
            @"Substitutions" : @"替换",
            @"Transformations" : @"转换",
            @"Speech" : @"语音",
            @"AutoFill" : @"自动填充",
            @"Start Dictation…" : @"开始听写…",
            @"Emoji & Symbols" : @"表情与符号",

            // View
            @"Refresh" : @"刷新",
            @"Force Refresh the Page" : @"强制刷新页面",
            @"Show Tabs in Sidebar" : @"在侧边栏显示标签页",
            @"Auto-Hide Tabs" : @"自动隐藏标签页",
            @"Open Split Pane" : @"打开分屏",
            @"Focus Next Split Pane" : @"聚焦下一个分屏",
            @"Focus Previous Split Pane" : @"聚焦上一个分屏",
            @"Show Bookmarks Bar" : @"显示书签栏",
            @"Show Full URL" : @"显示完整网址",
            @"Zoom to Actual Size" : @"缩放至实际大小",
            @"Zoom In" : @"放大",
            @"Zoom Out" : @"缩小",
            @"Enter Full Screen" : @"进入全屏",
            @"Developer" : @"开发者",

            // Tabs
            @"Go Back" : @"后退",
            @"Go Forward" : @"前进",
            @"Next Tab" : @"下一个标签页",
            @"Previous Tab" : @"上一个标签页",
            @"Previous Profile" : @"上一个配置文件",
            @"Next Profile" : @"下一个配置文件",
            @"Search Tabs…" : @"搜索标签页…",
            @"Pin/Unpin Tab" : @"固定/取消固定标签页",
            @"Pin as Tab" : @"固定为标签页",
            @"Duplicate Tab" : @"复制标签页",
            @"Reset Pinned Tab to Base URL" : @"将固定标签页重置为初始网址",
            @"New Group with Tabs" : @"用标签页新建组",
            @"Tab Switcher (forward)" : @"标签页切换器（向前）",
            @"Tab Switcher (backward)" : @"标签页切换器（向后）",
            @"Switch Profile" : @"切换配置文件",
            @"Group Selected Tabs by Domain" : @"按域名分组选中标签页",
            @"Expand All Tab Groups" : @"展开所有标签组",
            @"Collapse All Tab Groups" : @"折叠所有标签组",
            @"Ungroup This Domain" : @"取消该域名的分组",
            @"Ungroup All Domains" : @"取消所有域名的分组",

            // Bookmarks, History, Extensions
            @"Add to Bookmarks…" : @"添加到书签…",
            @"Manage Bookmarks" : @"管理书签",
            @"Show History…" : @"显示历史记录…",
            @"Add Extension…" : @"添加扩展…",
            @"Manage Extensions…" : @"管理扩展…",
            @"Pin Extensions…" : @"固定扩展…",

            // Window and Help
            @"Minimize" : @"最小化",
            @"Downloads" : @"下载",
            @"Profile" : @"配置文件",
            @"Open Profile Switcher" : @"打开配置文件切换器",
            @"Task Manager" : @"任务管理器",
            @"Merge All Windows" : @"合并所有窗口",
            @"Bring All to Front" : @"前置全部窗口",
            @"Chat with Support" : @"联系客服",
            @"Video Tour" : @"视频导览",
            @"Status" : @"状态",
            @"Copy Diagnostics" : @"复制诊断信息",
            @"Record Performance Issue…" : @"记录性能问题…",

            // Tweak titles
            @"Answer with Your Own Model" : @"用自己的模型回答",
            @"Dia answers with the Claude Code it ships. Point that at your own Anthropic-compatible model endpoint instead of Dia's servers. Dia starts a new agent the next time you chat." :
                @"Dia 用自带的 Claude Code 回答。把它的模型地址指向你自己的 Anthropic 兼容接口，不再经过 Dia 的服务器。Dia 会在你下次对话时启动新的 agent。",
            @"Chinese Interface" : @"中文界面",
            @"Translate Dia and its browser interface into Chinese. The command bar, web pages and text fields are left alone; Chromium's own pages switch after Dia restarts." :
                @"把 Dia 及其浏览器界面的文字换成中文。命令栏、网页内容和输入框不受影响；Chromium 自带的页面在重启 Dia 后生效。",
            @"Edge-to-Edge Web Pages" : @"网页贴边显示",
            @"Square Corners Next to Sidebar" : @"侧边栏旁的直角网页",
            @"Extensions Shortcut" : @"扩展快捷键",
            @"Always Show Address Field" : @"始终显示地址栏",
            @"Don’t Open Downloads List" : @"不自动打开下载列表",
            @"Hide Toolbar" : @"隐藏工具栏",
            @"Hide Chat Button" : @"隐藏对话按钮",
            @"Hide Sidebar Button" : @"隐藏侧边栏按钮",
            @"Hide Site Not Working Prompt" : @"隐藏网站异常提示",
            @"Show Toolbar on Hover" : @"悬停时显示工具栏",
            @"Show Toolbar on New Tabs" : @"新标签页显示工具栏",
            @"Toggle toolbar visibility" : @"切换工具栏显示",
            @"Show Toolbar with Sidebar" : @"侧边栏打开时显示工具栏",
            @"Show Toast When Copying URL" : @"复制网址时显示提示",
            @"Show Toolbar When Copying URL" : @"复制网址时显示工具栏",
            @"Show Loading Progress" : @"显示加载进度",
            @"Hide Site Color in Tab Bar" : @"隐藏标签栏的网站配色",
            @"Profile Emoji" : @"配置文件表情",
            @"Translucent Sidebar" : @"半透明侧边栏",
            @"Compact Sidebar Header" : @"紧凑侧边栏标题",
            @"Switch Profiles with ⌘1–9" : @"用 ⌘1–9 切换配置文件",
            @"Hide Chats Button" : @"隐藏对话列表按钮",
            @"Hide Pinned Tab Card" : @"隐藏固定标签页卡片",
            @"Hide Group Background" : @"隐藏标签组背景",
            @"Hide Pinned Tab Border" : @"隐藏固定标签页边框",
            @"Hide Recent Tabs Button" : @"隐藏最近标签页按钮",
            @"Tidy Tabs" : @"整理标签页",
            @"Unload Tabs" : @"卸载标签页",
            @"Save Page As" : @"页面另存为",
            @"Merge Subdomains" : @"合并子域名",
            @"Undo Closing a Tab" : @"撤销关闭标签页",
            @"Group Tabs by Domain" : @"按域名分组标签页",
            @"Close Tabs from Tab Switcher" : @"在标签页切换器中关闭",
            @"Hide Sleeping Tabs" : @"隐藏休眠标签页",
            @"Compact Command Bar" : @"紧凑命令栏",
            @"Compact with Chat Usage Too" : @"有对话额度时也紧凑",
            @"Open New Tabs in Command Bar" : @"在命令栏中打开新标签页",
            @"Hide Upgrade Banner" : @"隐藏升级横幅",
            @"Hide History Suggestions" : @"隐藏历史记录建议",
            @"Blur Page Behind" : @"模糊背景页面",
            @"Darken Page Behind" : @"压暗背景页面",
            @"Remember What You Typed" : @"记住输入内容",
            @"Hide New Tab Logo" : @"隐藏新标签页 Logo",
            @"Hide Skills Suggestions" : @"隐藏技能建议",
            @"Hide Personalize Button" : @"隐藏个性化按钮",
            @"Window Corners" : @"窗口圆角",
            @"Window Material" : @"窗口材质",
            @"Keep Windows Active" : @"窗口保持活跃",
            @"Drag Window from Page" : @"从页面拖动窗口",
            @"Hide Window Controls" : @"隐藏窗口按钮",
            @"Allow 1Password" : @"允许 1Password",
            @"Allow iCloud Passkeys" : @"允许 iCloud 通行密钥",
            @"Allow iCloud Passwords" : @"允许 iCloud 密码",
            @"Drag Links to Peek" : @"拖动链接预览",
            @"Peek on Shift-Click" : @"Shift 点击预览",
            @"Peek from Pinned Tabs" : @"从固定标签页预览",
            @"Hide Link Address" : @"隐藏链接地址",

            // Tweak page headings
            @"Showing the Toolbar" : @"显示工具栏",
            @"Copying the URL" : @"复制网址时",
            @"While It's Hidden" : @"隐藏时",
            @"Blur" : @"模糊",
            @"Darken" : @"压暗",
            @"Typing" : @"输入",

            // Tweak details
            @"Remove the padding between web pages and the window edge." : @"去掉网页与窗口边缘之间的留白。",
            @"Give web pages square corners where they meet the sidebar." : @"让网页与侧边栏相接处使用直角。",
            @"Press a shortcut, ⇧⌘X unless you set another, for a menu of your extensions. Choosing one opens it as its toolbar button would." :
                @"按快捷键（默认 ⇧⌘X）打开扩展菜单，选择扩展即像点击工具栏按钮一样打开它。",
            @"Show the address field’s background and its bookmark, split view and site buttons without pointing at it." :
                @"无需把指针移上去，也始终显示地址栏背景以及收藏、分屏和站点按钮。",
            @"Stop the downloads list from opening each time a download starts. The downloads button still shows progress." :
                @"下载开始时不再自动打开下载列表，下载按钮仍显示进度。",
            @"Hide the bar with the address field, navigation buttons and extensions. Experimental." :
                @"隐藏包含地址栏、导航按钮和扩展的工具栏。实验性功能。",
            @"Hide the Chat button at the top right of the toolbar." : @"隐藏工具栏右上角的对话按钮。",
            @"Hide the sidebar toggle at the top left of the toolbar." : @"隐藏工具栏左上角的侧边栏开关。",
            @"Stop the “not working correctly?” prompt that offers to turn off the ad blocker after you reload a page a few times." :
                @"多次重新加载页面后，不再弹出询问是否关闭广告拦截的“工作不正常？”提示。",
            @"Show the toolbar when you move the pointer to the top of the page." : @"指针移到页面顶部时显示工具栏。",
            @"Show the toolbar and bookmarks bar on new tab pages, and hide them once a site opens." :
                @"在新标签页显示工具栏和书签栏，打开网站后隐藏。",
            @"Hide or show the toolbar with a keyboard shortcut, ⌃D unless you set another." : @"用快捷键显示或隐藏工具栏，默认 ⌃D。",
            @"Show the toolbar while the sidebar is open." : @"侧边栏打开时显示工具栏。",
            @"Show a small Copied message at the top of the page after ⇧⌘C, and keep the toolbar hidden." :
                @"按 ⇧⌘C 后在页面顶部显示“已复制”提示，工具栏保持隐藏。",
            @"Show the toolbar for a moment after ⇧⌘C, so you see Dia's Copied message." :
                @"按 ⇧⌘C 后短暂显示工具栏，让你看到 Dia 的“已复制”提示。",
            @"Show Dia's loading glow along the top of the page while it loads, where the hidden toolbar would show it." :
                @"页面加载时在顶部显示 Dia 的加载光效，也就是隐藏工具栏所在的位置。",
            @"While the toolbar is hidden, show the selected tab in the page color instead of the site's." :
                @"工具栏隐藏时，选中标签页使用页面配色，而不是网站配色。",
            @"Show an emoji in place of each profile’s dot in the profile switcher. Choose them in Settings › Profiles." :
                @"在配置文件切换器中用表情代替每个配置文件的圆点。可在“设置 › 配置文件”中选择。",
            @"Show the page through the sidebar when it floats over it, in the window’s material or the one chosen in Window material." :
                @"侧边栏浮在页面上时让页面透出来，使用窗口材质或“窗口材质”中选择的材质。",
            @"Move the pinned tabs up into the empty space under the window buttons." : @"把固定标签页上移到窗口按钮下方的空白处。",
            @"Press ⌘ and a number to switch to that profile, like Arc's spaces. The sidebar's items move to ⌃ and a number." :
                @"按 ⌘ 加数字切换到对应配置文件，类似 Arc 的空间。侧边栏项目的快捷键移到 ⌃ 加数字。",
            @"Hide the Chats button in the tab bar or sidebar." : @"隐藏标签栏或侧边栏中的“对话”按钮。",
            @"Stop the card with a pinned tab's title and buttons from showing when you point at the tab." :
                @"指向固定标签页时，不再弹出显示标题和按钮的卡片。",
            @"Leave an open tab group without the grey behind it, unless you've picked a colour for the group." :
                @"打开的标签组不再显示灰色背景，除非你为它选了颜色。",
            @"Remove the colored border around the selected pinned tab." : @"去掉选中固定标签页的彩色边框。",
            @"Hide the recent tabs button in the tab bar or sidebar." : @"隐藏标签栏或侧边栏中的最近标签页按钮。",
            @"Adds a broom to the line above your tabs. Click it to group your tabs by what they’re for, using Apple Intelligence on your Mac; Dia names the groups. Shows with more than 5 tabs." :
                @"在标签页上方加一把扫帚。点击后用 Mac 上的 Apple 智能按用途给标签页分组，组名由 Dia 生成。标签页超过 5 个时显示。",
            @"Right-click a tab and choose Unload Tab to free its memory. It stays in the sidebar, dimmed, and loads again when you open it." :
                @"右键点击标签页并选择“卸载标签页”来释放内存。标签页会变暗留在侧边栏，再次打开时重新加载。",
            @"Add Save Page As… to the File menu, with a shortcut, ⌥⌘S unless you set another." :
                @"在“文件”菜单中加入“页面另存为…”，默认快捷键为 ⌥⌘S。",
            @"Group tabs from the same site together, so gist.github.com joins github.com." :
                @"把同一网站的标签页分到一组，例如 gist.github.com 会归入 github.com。",
            @"Press a shortcut, ⌘Z unless you set another, right after closing a tab to bring it back, as long as you haven’t typed or clicked since." :
                @"刚关闭标签页后按快捷键（默认 ⌘Z）即可恢复，前提是之后没有输入或点击。",
            @"Groups a window’s tabs by site, from the Tabs menu, a tab’s right-click menu or a shortcut." :
                @"从“标签页”菜单、标签页右键菜单或快捷键按网站给当前窗口的标签页分组。",
            @"Press W or ⌘W while the tab switcher (⌃⇥) is open to close the highlighted tab and keep switching." :
                @"标签页切换器（⌃⇥）打开时按 W 或 ⌘W 关闭高亮标签页并继续切换。",
            @"Leave tabs with nothing loaded, like a pinned tab you closed, out of the tab switcher (⌃⇥) instead of showing them as empty pictures." :
                @"没有加载内容的标签页（如已关闭的固定标签页）不再以空白预览出现在标签页切换器（⌃⇥）中。",
            @"Without chat usage, hide Add tabs or files and dictation so the command bar fits on one line." :
                @"没有对话额度时，隐藏“添加标签页或文件”和听写按钮，让命令栏保持一行。",
            @"Also hide Add tabs or files and dictation when you have chat usage. You can’t use them from the command bar while this is on." :
                @"有对话额度时也隐藏“添加标签页或文件”和听写按钮。开启后无法从命令栏使用它们。",
            @"Open new tabs as Dia’s command bar over the current page, like Arc. Choose a result to open it in a new tab, or press Escape to go back." :
                @"打开新标签页时像 Arc 一样在当前页面上方显示 Dia 的命令栏。选择结果会在新标签页打开，按 Escape 返回。",
            @"Hide the “Looking for chat?” upgrade banner under the command bar." :
                @"隐藏命令栏下方的“在找对话功能？”升级横幅。",
            @"Leave pages you've visited out of the suggestions in the address field and command bar. Searches and open tabs still show." :
                @"地址栏和命令栏的建议中不再出现浏览过的页面，搜索和已打开的标签页仍会显示。",
            @"Blur the page behind the command bar." : @"模糊命令栏后面的页面。",
            @"Darken the page behind the command bar." : @"压暗命令栏后面的页面。",
            @"Bring back what you typed when you open the bar again after Escape, selected so you can carry on or type over it." :
                @"按 Escape 后再次打开命令栏时恢复上次输入的内容，并选中以便继续输入或直接覆盖。",
            @"Hide the Dia logo above the search field on new tab pages." : @"隐藏新标签页搜索框上方的 Dia 标志。",
            @"Hide the Skills and Learn Skills buttons under the search field on new tab pages." :
                @"隐藏新标签页搜索框下方的“技能”和“了解技能”按钮。",
            @"Hide the Personalization button at the top right of new tab pages." : @"隐藏新标签页右上角的个性化按钮。",
            @"Round Dia’s windows like other apps on macOS 26, or pick a smaller radius down to square, with the page’s corners to match." :
                @"像 macOS 26 上的其他应用一样给 Dia 窗口加圆角，也可以选更小的圆角直至直角，网页边角会同步。",
            @"Show a material or Liquid Glass behind the tabs and sidebar, still tinted with the profile’s color." :
                @"在标签页和侧边栏后面显示材质或 Liquid Glass，仍带有配置文件颜色。",
            @"Keep windows looking active, with their shadow, sidebar color and window buttons, when you switch to another app. Experimental." :
                @"切换到其他应用时，窗口仍保持活跃外观，包括阴影、侧边栏颜色和窗口按钮。实验性功能。",
            @"Drag an empty spot near the top of a page to move the window, like a title bar. Handy with the toolbar and sidebar hidden." :
                @"拖动页面顶部空白处即可移动窗口，像拖动标题栏一样。隐藏工具栏和侧边栏时很好用。",
            @"Hide the close, minimize and zoom buttons. ⌘W, ⌘M and the Window menu still work." :
                @"隐藏关闭、最小化和缩放按钮。⌘W、⌘M 和“窗口”菜单仍可用。",
            @"Connect the 1Password extension to the 1Password app. The app turns away a patched Dia, so while the extension is connected, the original Dia that DiaTweaks keeps runs in the background to talk to it. Experimental." :
                @"让 1Password 扩展连接到 1Password 应用。该应用会拒绝打补丁的 Dia，因此扩展连接期间，DiaTweaks 保留的原始 Dia 会在后台运行并与它通信。实验性功能。",
            @"Sign in to sites with passkeys saved in Apple Passwords. A patched Dia can’t reach them, so the original Dia that DiaTweaks keeps opens behind the Touch ID prompt, then quits. Experimental." :
                @"用保存在 Apple 密码中的通行密钥登录网站。打补丁的 Dia 无法访问它们，因此 DiaTweaks 保留的原始 Dia 会在 Touch ID 提示后面打开，随后退出。实验性功能。",
            @"AutoFill passwords from Apple Passwords with the iCloud Passwords extension. A patched Dia can’t start Apple’s helper, so each time the extension connects, the original Dia that DiaTweaks keeps opens for a moment, without windows, to start it. Experimental." :
                @"用 iCloud 密码扩展自动填充 Apple 密码中的密码。打补丁的 Dia 无法启动 Apple 的辅助进程，因此每次扩展连接时，DiaTweaks 保留的原始 Dia 会短暂打开（无窗口）来启动它。实验性功能。",
            @"Drag a link and a small card appears above it. Drop the link on the card to open it in Peek, no Shift needed." :
                @"拖动链接时上方会出现小卡片，把链接放到卡片上即可在预览中打开，无需按 Shift。",
            @"Shift-click a link to preview it in a card over the page, like Arc. Click outside, press Escape or ⌘W to close it, ⌘O to open it as a tab, or use the buttons beside it." :
                @"Shift 点击链接可在页面上方的卡片中预览，类似 Arc。点击外部、按 Escape 或 ⌘W 关闭，按 ⌘O 在新标签页打开，也可以使用旁边的按钮。",
            @"Open a link that leaves a pinned tab's site in Peek, like Arc, instead of in a new tab. Links on the same site still open in the pinned tab." :
                @"从固定标签页打开站外链接时使用预览而不是新标签页，类似 Arc。同一网站的链接仍在固定标签页中打开。",
            @"Hide the address that shows at the bottom of the page when you point at a link." :
                @"指向链接时不再在页面底部显示地址。",
        };
    });
    return strings;
}
