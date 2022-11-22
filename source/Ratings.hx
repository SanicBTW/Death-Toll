package;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;

using StringTools;

class Ratings
{
	// follows the timings.hx judgementsMap structure on Forever Engine Legacy
	public static var judgementsMap:Map<String, Array<Dynamic>> = [
		"sick" => [0, SaveData.get(SICK_WINDOW), 350, 1],
		"good" => [1, SaveData.get(GOOD_WINDOW), 150, 0.75],
		"bad" => [2, SaveData.get(BAD_WINDOW), 0, 0.5],
		"shit" => [3, SaveData.get(SHIT_WINDOW), -50, 0.25],
		"miss" => [4, 180, -100, -1], // no missWindow or smth so 180, idk if i should -1 on totalNotesHit uhh
	];

	// tf bruh ??? :sob:
	public static function preparePos()
	{
		var coolText:FlxText = new FlxText(0, 0, 0, '', 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;
		basePos = coolText.x;
	}

	private static var basePos:Float = 0;
	public static function generateCombo(number:String, allSicks:Bool, negative:Bool, createdColor:FlxColor, scoreInt:Int):FlxSprite
	{
		var width = 100;
		var height = 140;
		var path = Paths.getLibraryPath('${SaveData.get(COMBOS_STYLE)}/combo.png', "UILib");
		var graphic = Paths.getGraphic(path);

		var newSprite:FlxSprite = new FlxSprite().loadGraphic(graphic, true, width, height);
		newSprite.alpha = 1;
		newSprite.screenCenter();
		newSprite.x = basePos + (43 * scoreInt) - 90;
		newSprite.y += 80;

		newSprite.visible = (!SaveData.get(HIDE_HUD));
		newSprite.x += SaveData.get(COMBO_OFFSET)[2];
		newSprite.y -= SaveData.get(COMBO_OFFSET)[3];

		newSprite.color = FlxColor.WHITE;
		if (negative)
			newSprite.color = createdColor;

		newSprite.animation.add('base', [
			(Std.parseInt(number) != null ? Std.parseInt(number) + 1 : 0) + (!allSicks ? 0 : 11)
		], 0, false);
		newSprite.animation.play('base');

		newSprite.antialiasing = SaveData.get(ANTIALIASING);
		newSprite.setGraphicSize(Std.int(newSprite.width * 0.5));

		newSprite.updateHitbox();
		newSprite.acceleration.y = FlxG.random.int(200, 300);
		newSprite.velocity.x = FlxG.random.float(-5, 5);
		newSprite.velocity.y -= FlxG.random.int(140, 160);

		return newSprite;
	}

	public static function generateRating(ratingName:String, perfectSick:Bool, timing:String):FlxSprite
	{
		var width = 500;
		var height = 163;
		var path = Paths.getLibraryPath('${SaveData.get(RATINGS_STYLE)}/judgements.png', "UILib");
		var graphic = Paths.getGraphic(path);

		var rating:FlxSprite = new FlxSprite().loadGraphic(graphic, true, width, height);
		rating.alpha = 1;
		rating.screenCenter();
		rating.x = basePos - 40;
		rating.y -= 60;

		rating.visible = (!SaveData.get(HIDE_HUD));
		rating.x += SaveData.get(COMBO_OFFSET)[0];
		rating.y -= SaveData.get(COMBO_OFFSET)[1];

		rating.animation.add('base', [
			Std.int((judgementsMap.get(ratingName)[0] * 2) + (perfectSick ? 0 : 2) + (timing == "late" ? 1 : 0))
		], 24, false);
		rating.animation.play('base');

		rating.antialiasing = SaveData.get(ANTIALIASING);
		rating.setGraphicSize(Std.int(rating.width * 0.7));

		rating.updateHitbox();
		rating.acceleration.y = 550;
		rating.velocity.x -= FlxG.random.int(0, 10);
		rating.velocity.y -= FlxG.random.int(140, 175);

		return rating;
	}

	public static function judgeNote(ms:Float)
	{
		var ts:Float = Conductor.timeScale;
		// dumb ass
		var timingWindows = 
		[
			judgementsMap.get("sick")[1],
			judgementsMap.get("good")[1],
			judgementsMap.get("bad")[1],
			judgementsMap.get("shit")[1],
			judgementsMap.get("miss")[1],
		];
		var ratings = ["sick", "good", "bad", "shit"];

		for (i in 0...timingWindows.length)
		{
			if (ms <= timingWindows[Math.round(Math.min(i, timingWindows.length - 1))] * ts)
			{
				return ratings[i];
			}
		}

		return 'miss';
	}
}
