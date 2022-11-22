package options;

class RatingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = "Ratings Settings";
		rpcTitle = "Ratings Settings Menu";

		var option:Option = new Option('Ratings Style:', "The style of Ratings",
			RATINGS_STYLE, "string", "Default", ["Default", "SimplyLove"]);
		addOption(option);

		var option:Option = new Option('Combos Style:', "The style of Combos",
			COMBOS_STYLE, "string", "Default", ["Default", "SimplyLove"]);
		addOption(option);

		super();
	}
}
