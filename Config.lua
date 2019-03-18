local _, addonTable = ...;
local StdUi = LibStub('StdUi');

--- @type MaxDps
if not MaxDps then return end
local MaxDps = MaxDps;
local Hunter = addonTable.Hunter;

local defaultOptions = {
	advancedAoeBM = true,
	huntersMarkCooldown = false,
	doubleTapCooldown = false,
};

function Hunter:GetConfig()
	local config = {
		layoutConfig = { padding = { top = 30 } },
		database     = self.db,
		rows         = {
			[1] = {
				beastmastery = {
					type = 'header',
					label = 'Beast Mastery options'
				}
			},
			[2] = {
				advancedAoeBM = {
					type   = 'checkbox',
					label  = 'Advanced AOE detection (need to put pet basic attack on YOUR action bars)',
					column = 12
				},
			},
			[3] = {
				beastmastery = {
					type = 'header',
					label = 'Marksmanship options'
				}
			},
			[4] = {
				huntersMarkCooldown = {
					type   = 'checkbox',
					label  = 'Hunters Mark as cooldown',
					column = 6
				},
				doubleTapCooldown = {
					type   = 'checkbox',
					label  = 'Double Tap as cooldown',
					column = 6
				},
			},
		},
	};

	return config;
end


function Hunter:InitializeDatabase()
	if self.db then return end;

	if not MaxDpsHunterOptions then
		MaxDpsHunterOptions = defaultOptions;
	end

	self.db = MaxDpsHunterOptions;
end

function Hunter:CreateConfig()
	if self.optionsFrame then
		return;
	end

	local optionsFrame = StdUi:PanelWithTitle(nil, 100, 100, 'Hunter Options');
	self.optionsFrame = optionsFrame;
	optionsFrame:Hide();
	optionsFrame.name = 'Hunter';
	optionsFrame.parent = 'MaxDps';

	StdUi:BuildWindow(self.optionsFrame, self:GetConfig());

	StdUi:EasyLayout(optionsFrame, { padding = { top = 40 } });

	optionsFrame:SetScript('OnShow', function(of)
		of:DoLayout();
	end);

	InterfaceOptions_AddCategory(optionsFrame);
	InterfaceCategoryList_Update();
	InterfaceOptionsOptionsFrame_RefreshCategories();
	InterfaceAddOnsList_Update();
end