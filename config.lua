local _, addonTable = ...;
local StdUi = LibStub('StdUi');

--- @type MaxDps
if not MaxDps then return end
local MaxDps = MaxDps;
local Hunter = addonTable.Hunter;

function Hunter:CreateConfig()
	if self.optionsFrame then
		return;
	end

	local optionsFrame = StdUi:PanelWithTitle(nil, 100, 100, 'Hunter Options');
	self.optionsFrame = optionsFrame;
	optionsFrame:Hide();
	optionsFrame.name = 'Hunter';
	optionsFrame.parent = MaxDps.optionsFrame;

	StdUi:EasyLayout(optionsFrame, { padding = { top = 40 } });


	optionsFrame:SetScript('OnShow', function(of)
		of:DoLayout();
	end);

	InterfaceOptions_AddCategory(optionsFrame);
end