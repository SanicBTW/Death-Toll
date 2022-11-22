package;

import flixel.math.FlxMath;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.text.FlxText;
import flixel.ui.FlxBar;
import flixel.FlxBasic;
import flixel.group.FlxGroup.FlxTypedGroup;

using StringTools;

// make it compatible with other states? ex: not to use playstate is pixel and use an arg or smth
class HUD extends FlxTypedGroup<FlxBasic>
{
	private var healthBarBG:AttachedSprite;

	private var healthBar:FlxBar;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;

	public var scoreTxt:FlxText;
    private var feWatermark:FlxText;
    private var songMark:FlxText;

	private var scoreTxtTween:FlxTween;

    public function new(iconP1Det:IconDetails, iconP2Det:IconDetails)
    {
        super();

        var hideHud = SaveData.get(HIDE_HUD);
        var downScroll = SaveData.get(DOWN_SCROLL);

        healthBarBG = new AttachedSprite('healthBar');
        healthBarBG.y = FlxG.height * 0.89;
        if (downScroll)
            healthBarBG.y = 0.11 * FlxG.height;
        healthBarBG.screenCenter(X);
        healthBarBG.scrollFactor.set();
        healthBarBG.visible = !hideHud;
        healthBarBG.xAdd = -4;
        healthBarBG.yAdd = -4;
        add(healthBarBG);

        healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this, '', 0, 2);
        healthBar.scrollFactor.set();
        healthBar.visible = !hideHud;
        add(healthBar);
        healthBarBG.sprTracker = healthBar;

        iconP1 = new HealthIcon(iconP1Det.name, true);
        iconP1.y = healthBar.y - (iconP1.height / 2);
        add(iconP1);

        iconP2 = new HealthIcon(iconP2Det.name, false);
        iconP2.y = healthBar.y - (iconP2.height / 2);
        add(iconP2);
        reloadHealthBarColors(iconP1Det, iconP2Det);

        scoreTxt = new FlxText(0, healthBarBG.y + 36, FlxG.width, "", 20);
        scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        scoreTxt.scrollFactor.set();
        scoreTxt.borderSize = 1.25;
        scoreTxt.visible = !hideHud;
        add(scoreTxt);

        feWatermark = new FlxText(0, 0, 0, "FOREVER ENGINE LEGACY v" + MainMenuState.feEngineVersion, 18);
        feWatermark.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE);
        feWatermark.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
        feWatermark.setPosition(FlxG.width - (feWatermark.width + 5), 5);
        feWatermark.antialiasing = SaveData.get(ANTIALIASING);
        add(feWatermark);
    
        // hardcoded to hard cuz its the only diff lol, if you want to change it to bind the song diff ask me for it or find you way
        songMark = new FlxText(0, (downScroll ? FlxG.height - 40 : 10), 0, '- ${Paths.formatToSongPath(PlayState.SONG.song).toUpperCase().replace("-", " ")} [HARD] -');
        songMark.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE);
        songMark.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
        songMark.screenCenter(X);
        songMark.antialiasing = SaveData.get(ANTIALIASING);
        add(songMark);
    }

    private function reloadHealthBarColors(iconP1Det:IconDetails, iconP2Det:IconDetails)
    {
        healthBar.createFilledBar(FlxColor.fromRGB(iconP2Det.healthColors[0], iconP2Det.healthColors[1], iconP2Det.healthColors[2]),
            FlxColor.fromRGB(iconP1Det.healthColors[0], iconP1Det.healthColors[1], iconP1Det.healthColors[2]));
        healthBar.updateBar();
    }

    public function doScoreZoom()
    {
        if (SaveData.get(SCORE_ZOOM))
        {
            if (scoreTxtTween != null)
                scoreTxtTween.cancel();

            scoreTxt.scale.set(1.075, 1.075);
            scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
                onComplete: function(twn:FlxTween)
                {
                    scoreTxtTween = null;
                }
            });
        }
    }

    override public function update(elapsed:Float)
    {
        scoreTxt.text = getScoreFormat();
        healthBar.value = PlayState.instance.health;

        // make it change graphic size instead of scale?
        var mult:Float = FlxMath.lerp(1, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

        var mult:Float = FlxMath.lerp(1, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

        var iconOffset:Int = 26;

		iconP1.x = healthBar.x
			+ (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01))
			+ (150 * iconP1.scale.x - 150) / 2
			- iconOffset;
		iconP2.x = healthBar.x
			+ (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01))
			- (150 * iconP2.scale.x) / 2
			- iconOffset * 2;

        if (healthBar.percent < 20)
			iconP1.animation.curAnim.curFrame = 1;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (healthBar.percent > 80)
			iconP2.animation.curAnim.curFrame = 1;
		else
			iconP2.animation.curAnim.curFrame = 0;
    }

    private function getScoreFormat():String
    {
        // :P
        var songScore = PlayState.instance.songScore;
        var songMisses = PlayState.instance.songMisses;
        var ratingString = PlayState.instance.ratingString;
        var ratingFC = PlayState.instance.ratingFC;
        var ratingPercent = PlayState.instance.ratingPercent;

        switch (SaveData.get(SCORE_TEXT_STYLE))
		{
			case 'Forever':
				if (ratingString == "N/A")
				{
					return 'Score: $songScore • Accuracy: 0% • Combo Breaks: $songMisses • Rank: N/A';
				}
				else
				{
					return 'Score: $songScore • Accuracy: ${Highscore.floorDecimal(ratingPercent * 100, 2)}% [$ratingFC] • Combo Breaks: $songMisses • Rank: $ratingString';
				}
			case 'Engine':
				if (ratingString == 'N/A')
				{
					return 'Score: $songScore | Misses: $songMisses | $ratingString';
				}
				else
				{
					return 'Score: $songScore | Misses: $songMisses | Accuracy: ${Highscore.floorDecimal(ratingPercent * 100, 2)}% | $ratingString ($ratingFC)';
				}
			case 'Psych':
				if (ratingString == '?')
				{
					return 'Score: $songScore | Misses: $songMisses | Rating: $ratingString';
				}
				else
				{
					return 'Score: $songScore | Misses: $songMisses | Rating: $ratingString (${Highscore.floorDecimal(ratingPercent * 100, 2)}%) - $ratingFC';
				}
		}
		return "";
    }

    // stuff from forever lol 
    public function beatHit()
    {
        iconP1.setGraphicSize(Std.int(iconP1.width + 30));
        iconP2.setGraphicSize(Std.int(iconP2.width + 30));

		iconP1.updateHitbox();
		iconP2.updateHitbox();
    }
}

// xd
typedef IconDetails = 
{
    name:String,
    healthColors:Array<Int>
} 