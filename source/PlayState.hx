package;

import DialogueBoxPsych;
import Note.EventNote;
import Section.SwagSection;
import Song.SwagSong;
import StageData.StageFile;
import animateatlas.AtlasFrameMaker;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.ui.FlxButton;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import notes.StrumLine;
import notes.UIStaticArrow;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.ShaderFilter;
import openfl.media.Sound;
import openfl.media.Video;
import openfl.system.System;
import openfl.utils.Assets as OpenFlAssets;
import substates.*;

using StringTools;

#if desktop
import Discord.DiscordClient;
#end

class PlayState extends MusicBeatState
{
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;
	public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', 0.2], // From 0% to 19%
		['Shit', 0.4], // From 20% to 39%
		['Bad', 0.5], // From 40% to 49%
		['Bruh', 0.6], // From 50% to 59%
		['Meh', 0.69], // From 60% to 68%
		['Nice', 0.7], // 69%
		['Good', 0.8], // From 70% to 79%
		['Great', 0.9], // From 80% to 89%
		['Sick!', 1], // From 90% to 99%
		['Perfect!', 1] // The value on this one isn't used actually, since Perfect is always "1"
	];

	// event variables
	private var isCameraOnForcedPos:Bool = false;

	public var boyfriendMap:Map<String, Boyfriend> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	public var spawnTime:Float = 2000;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;

	public static var curStage:String = '';
	public static var isPixelStage:Bool = false;
	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var dad:Character;
	public var gf:Character;
	public var boyfriend:Character;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<Dynamic> = [];

	private var lastSection:Int = 0;
	private var camFollow:FlxPoint;
	private var camFollowPos:FlxObject;

	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

	private var camZooming:Bool = true;
	private var curSong:String = "";
	private var gfSpeed:Int = 1;
	public var health:Float = 1;
	private var combo:Int = 0;

	private var generatedMusic:Bool = false;
	private var endingSong:Bool = false;
	private var startingSong:Bool = false;

	public static var chartingMode:Bool = false;

	// Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;

	var botplaySine:Float = 0;

	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];
	var dialogueJson:DialogueFile = null;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;

	public static var daPixelZoom:Float = 6;

	var singAnims = ["singLEFT", "singDOWN", "singUP", "singRIGHT"];

	public var inCutscene:Bool = false;

	var songLength:Float = 0;

	public static var displaySongName:String = "";

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;
	public var introSoundsSuffix:String = '';

	// stores the last judgement object
	public static var lastRating:FlxSprite;
	// stores the last combo sprite object
	public static var lastScore:Array<FlxSprite> = [];

	var camDisplaceX:Float = 0;
	var camDisplaceY:Float = 0;

	var mashViolations:Int = 0;

	public static var instance:PlayState; // for the dumb week 7 shit

	// used for events coming from online or storage song, ik i should use
	// the get content on generate song shit but nahhh gonna make it much easier lol
	public static var songEvents:Array<Dynamic> = null;

	var vocals:FlxSound;

	public static var instSource:Dynamic = null;
	public static var voicesSource:Dynamic = null;

	private var dadStrums:StrumLine;
	private var boyfriendStrums:StrumLine;

	public static var strumLines:FlxTypedGroup<StrumLine>;
	public static var strumHUD:Array<FlxCamera> = [];

	private var allUIs:Array<FlxCamera> = [];
	public static var uiHUD:HUD;

	override public function create()
	{
		instance = this;

		Paths.clearCache(false, false);

		PauseSubState.songName = null; // Reset to default
		Conductor.recalculateTimings();

		//wtf dwag
		Ratings.preparePos();

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		healthGain = SaveData.getGameplaySetting('healthgain', 1);
		healthLoss = SaveData.getGameplaySetting('healthloss', 1);
		instakillOnMiss = SaveData.getGameplaySetting('instakill', false);
		practiceMode = SaveData.getGameplaySetting('practice', false);
		cpuControlled = SaveData.getGameplaySetting('botplay', false);

		if (Assets.exists(Paths.inst(SONG.song)) && instSource == null)
			instSource = Paths.inst(SONG.song);

		if (Assets.exists(Paths.voices(SONG.song)) && voicesSource == null)
			voicesSource = Paths.voices(SONG.song);
		else if (!Assets.exists(Paths.voices(SONG.song)) && voicesSource == null)
			SONG.needsVoices = false;

		practiceMode = false;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);
		allUIs.push(camHUD);

		strumLines = new FlxTypedGroup<StrumLine>();

		var placement = (FlxG.width / 2);
		dadStrums = new StrumLine(placement + FlxG.width / 4, 4, true);
		dadStrums.visible = false;
		boyfriendStrums = new StrumLine(placement - (!SaveData.get(MIDDLE_SCROLL) ? (FlxG.width / 4) : 0), 4, false);

		strumLines.add(dadStrums);
		strumLines.add(boyfriendStrums);

		strumHUD = [];
		for (i in 0...strumLines.length)
		{
			strumHUD[i] = new FlxCamera();
			strumHUD[i].bgColor.alpha = 0;

			strumHUD[i].cameras = [camHUD];
			allUIs.push(strumHUD[i]);
			FlxG.cameras.add(strumHUD[i]);

			strumLines.members[i].cameras = [strumHUD[i]];
		}
		add(strumLines);

		// for making hud over the notes, stupid but better tbh lol
		var hudcam = new FlxCamera();
		hudcam.bgColor.alpha = 0;
		allUIs.push(hudcam);
		FlxG.cameras.add(hudcam);

		FlxG.cameras.add(camOther);

		FlxCamera.defaultCameras = [camGame];
		CustomFadeTransition.nextCamera = camOther;

		persistentUpdate = true;
		persistentDraw = true;

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		var songName:String = SONG.song;
		displaySongName = StringTools.replace(songName, '-', ' ');

		#if desktop
		storyDifficultyText = CoolUtil.difficulties[storyDifficulty];

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
		{
			detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
		}
		else
		{
			detailsText = "Freeplay";
		}

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		GameOverSubstate.resetVariables();
		var songName:String = Paths.formatToSongPath(SONG.song);

		curStage = PlayState.SONG.stage;
		trace('stage is: ' + curStage);
		if (PlayState.SONG.stage == null || PlayState.SONG.stage.length < 1)
		{
			switch (songName)
			{
				default:
					curStage = 'stage';
			}
		}
		PlayState.SONG.stage = curStage;

		var stageData:StageFile = StageData.getStageFile(curStage);
		if (stageData == null)
		{ // Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
				directory: "",
				defaultZoom: 0.9,
				isPixelStage: false,

				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100],
				hide_girlfriend: false,

				camera_boyfriend: [0, 0],
				camera_opponent: [0, 0],
				camera_girlfriend: [0, 0],
				camera_speed: 1
			};
		}

		defaultCamZoom = stageData.defaultZoom;
		isPixelStage = stageData.isPixelStage;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		if (stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if (boyfriendCameraOffset == null) // Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if (opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if (girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		switch (curStage)
		{
			case 'stage': // Week 1
				var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
				add(bg);

				var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				add(stageFront);
				if (!SaveData.get(LOW_QUALITY))
				{
					var stageLight:BGSprite = new BGSprite('stage_light', -125, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					add(stageLight);
					var stageLight:BGSprite = new BGSprite('stage_light', 1225, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					stageLight.flipX = true;
					add(stageLight);

					var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);
					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
					stageCurtains.updateHitbox();
					add(stageCurtains);
				}
		}

		if (isPixelStage)
		{
			introSoundsSuffix = '-pixel';
		}

		add(gfGroup);
		add(dadGroup);
		add(boyfriendGroup);

		var file:String = Paths.json(songName + '/dialogue'); // Checks for json/Psych Engine dialogue
		if (OpenFlAssets.exists(file))
		{
			dialogueJson = DialogueBoxPsych.parseDialogue(file);
		}

		var gfVersion:String = SONG.gfVersion;
		if (gfVersion == null || gfVersion.length < 1)
		{
			switch (curStage)
			{
				default:
					gfVersion = 'gf';
			}

			SONG.player3 = gfVersion; // Fix for the Chart Editor
		}

		if (!stageData.hide_girlfriend)
		{
			gf = new Character(0, 0, gfVersion);
			startCharacterPos(gf);
			gf.scrollFactor.set(0.95, 0.95);
			gfGroup.add(gf);
		}

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);

		boyfriend = new Boyfriend(0, 0, SONG.player1);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);

		var camPos:FlxPoint = new FlxPoint(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if (gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}

		if (dad.curCharacter.startsWith('gf'))
		{
			dad.setPosition(GF_X, GF_Y);
			if (gf != null)
				gf.visible = false;
		}

		Conductor.songPosition = -5000;

		uiHUD = new HUD(
			{
				name: boyfriend.healthIcon,
				healthColors: boyfriend.healthColorArray
			},
			{
				name: dad.healthIcon,
				healthColors: dad.healthColorArray
			}
		);
		add(uiHUD);
		uiHUD.cameras = [hudcam];

		generateSong();

		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		#if android
		addAndroidControls();
		androidControls.visible = false;
		addPadCamera();
		#end

		startingSong = true;

		precache();

		startCountdown();
		RecalculateRating();

		#if desktop
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, displaySongName + " (" + storyDifficultyText + ")", uiHUD.iconP2.getCharacter());
		#end

		super.create();

		CustomFadeTransition.nextCamera = camOther;
	}

	function set_songSpeed(value:Float):Float
	{
		if (generatedMusic)
		{
			var ratio:Float = value / songSpeed; // funny word huh
			for (note in dadStrums.allNotes)
				note.resizeByRatio(ratio);
			for (note in boyfriendStrums.allNotes)
				note.resizeByRatio(ratio);
			for (note in unspawnNotes)
				note.resizeByRatio(ratio);
		}
		songSpeed = value;
		noteKillOffset = 350 / songSpeed;
		return value;
	}

	public function addCharacterToList(newCharacter:String, type:Int)
	{
		switch (type)
		{
			case 0:
				if (!boyfriendMap.exists(newCharacter))
				{
					var newBoyfriend:Boyfriend = new Boyfriend(0, 0, newCharacter);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					newBoyfriend.alreadyLoaded = false;
				}

			case 1:
				if (!dadMap.exists(newCharacter))
				{
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					newDad.alreadyLoaded = false;
				}

			case 2:
				if (!gfMap.exists(newCharacter))
				{
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					newGf.alreadyLoaded = false;
				}
		}
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false)
	{
		if (gfCheck && char.curCharacter.startsWith('gf'))
		{ // IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	var dialogueCount:Int = 0;

	public var psychDialogue:DialogueBoxPsych;

	// You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if (psychDialogue != null)
			return;

		if (dialogueFile.dialogue.length > 0)
		{
			inCutscene = true;
			Main.tweenFPS(false, 0.5);
			Main.tweenMemory(false, 0.5);
			CoolUtil.precacheSound('dialogue');
			CoolUtil.precacheSound('dialogueClose');
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if (endingSong)
			{
				psychDialogue.finishThing = function()
				{
					psychDialogue = null;
					endSong();
				}
			}
			else
			{
				psychDialogue.finishThing = function()
				{
					psychDialogue = null;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		}
		else
		{
			FlxG.log.warn('Your dialogue file is badly formatted!');
			if (endingSong)
			{
				endSong();
			}
			else
			{
				startCountdown();
			}
		}
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;
	var perfectMode:Bool = false;

	public function startCountdown():Void
	{
		if (startedCountdown)
		{
			return;
		}

		#if android
		androidControls.visible = true;
		#end

		Main.tweenFPS(true, 0.5);
		Main.tweenMemory(true, 0.5);

		inCutscene = false;

		startedCountdown = true;
		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * 5;

		var swagCounter:Int = 0;

		startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
		{
			if (gf != null
				&& tmr.loopsLeft % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0
				&& !gf.stunned
				&& gf.animation.curAnim.name != null
				&& !gf.animation.curAnim.name.startsWith("sing")
				&& !gf.stunned)
			{
				gf.dance();
			}
			if (tmr.loopsLeft % boyfriend.danceEveryNumBeats == 0
				&& boyfriend.animation.curAnim != null
				&& !boyfriend.animation.curAnim.name.startsWith('sing')
				&& !boyfriend.stunned)
			{
				boyfriend.dance();
			}
			if (tmr.loopsLeft % dad.danceEveryNumBeats == 0
				&& dad.animation.curAnim != null
				&& !dad.animation.curAnim.name.startsWith('sing')
				&& !dad.stunned)
			{
				dad.dance();
			}

			var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
			introAssets.set('default', ['ready', 'set', 'go']);
			introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

			var introAlts:Array<String> = introAssets.get('default');
			var antialias:Bool = SaveData.get(ANTIALIASING);
			if (isPixelStage)
			{
				introAlts = introAssets.get('pixel');
				antialias = false;
			}

			switch (swagCounter)
			{
				case 0:
					FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
				case 1:
					var ready:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
					ready.cameras = [camHUD];
					ready.scrollFactor.set();
					ready.updateHitbox();

					if (isPixelStage)
						ready.setGraphicSize(Std.int(ready.width * daPixelZoom));

					ready.screenCenter();
					ready.antialiasing = antialias;
					add(ready);
					FlxTween.tween(ready, {y: ready.y + 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							ready.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
				case 2:
					var set:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
					set.cameras = [camHUD];
					set.scrollFactor.set();
					set.updateHitbox();

					if (isPixelStage)
						set.setGraphicSize(Std.int(set.width * daPixelZoom));

					set.screenCenter();
					set.antialiasing = antialias;
					add(set);
					FlxTween.tween(set, {y: set.y + 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							set.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
				case 3:
					var go:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
					go.cameras = [camHUD];
					go.scrollFactor.set();
					go.updateHitbox();

					if (isPixelStage)
						go.setGraphicSize(Std.int(go.width * daPixelZoom));

					go.screenCenter();
					go.antialiasing = antialias;
					add(go);
					FlxTween.tween(go, {y: go.y + 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							go.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
				case 4:
			}

			if (generatedMusic)
			{
				dadStrums.allNotes.sort(FlxSort.byY, SaveData.get(DOWN_SCROLL) ? FlxSort.ASCENDING : FlxSort.DESCENDING);
				boyfriendStrums.allNotes.sort(FlxSort.byY, SaveData.get(DOWN_SCROLL) ? FlxSort.ASCENDING : FlxSort.DESCENDING);
			}

			swagCounter += 1;
		}, 5);
	}

	function startNextDialogue()
	{
		dialogueCount++;
	}

	function startSong():Void
	{
		System.gc();

		startingSong = false;

		FlxG.sound.playMusic(instSource, 1, false);
		FlxG.sound.music.onComplete = finishSong;
		if (SONG.needsVoices)
			vocals.play();

		if (paused)
		{
			FlxG.sound.music.pause();
			if (SONG.needsVoices)
				vocals.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;

		#if desktop
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, displaySongName + " (" + storyDifficultyText + ")", uiHUD.iconP2.getCharacter(), true, songLength);
		#end

		camZooming = true;
	}

	private function generateSong():Void
	{
		System.gc();

		songSpeedType = SaveData.getGameplaySetting('scrolltype', 'multiplicative');

		switch (songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * SaveData.getGameplaySetting('scrollspeed', 1);
			case "constant":
				songSpeed = SaveData.getGameplaySetting('scrollspeed', 1);
		}

		curSong = SONG.song;

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(voicesSource);
		else
			vocals = new FlxSound();

		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(new FlxSound().loadEmbedded(instSource));

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = SONG.notes;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		if (songEvents != null)
		{
			for (event in songEvents)
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:EventNote = {
						strumTime: newEventNote[0] + SaveData.get(NOTE_OFFSET),
						event: newEventNote[1],
						value1: newEventNote[2],
						value2: newEventNote[3]
					};
					subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
					eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
		}
		else
		{
			var songName:String = Paths.formatToSongPath(SONG.song);
			var file:String = Paths.json(songName + '/events');
			if (OpenFlAssets.exists(file))
			{
				var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
				for (event in eventsData) // Event Notes
				{
					for (i in 0...event[1].length)
					{
						var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
						var subEvent:EventNote = {
							strumTime: newEventNote[0] + SaveData.get(NOTE_OFFSET),
							event: newEventNote[1],
							value1: newEventNote[2],
							value2: newEventNote[3]
						};
						subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
						eventNotes.push(subEvent);
						eventPushed(subEvent);
					}
				}
			}
		}

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				if (songNotes[1] > -1) // REAL NOTES FFS I HATE MY LIFE SO MUCH
				{
					var daStrumTime:Float = songNotes[0];
					var daNoteData:Int = Std.int(songNotes[1] % 4);

					var gottaHitNote:Bool = section.mustHitSection;

					if (songNotes[1] > 3)
						gottaHitNote = !section.mustHitSection;

					var oldNote:Note;
					if (unspawnNotes.length > 0)
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
					else
						oldNote = null;

					var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
					swagNote.mustPress = gottaHitNote;
					swagNote.sustainLength = songNotes[2];
					swagNote.gfNote = (section.gfSection && (songNotes[1] < 4));
					swagNote.noteType = songNotes[3];
					if (!Std.isOfType(songNotes[3], String))
						swagNote.noteType = ChartingState.noteTypeList[songNotes[3]];

					swagNote.scrollFactor.set();

					var susLength:Float = swagNote.sustainLength;

					susLength = susLength / Conductor.stepCrochet;
					unspawnNotes.push(swagNote);

					var floorSus:Int = Math.floor(susLength);

					if (floorSus > 0)
					{
						for (susNote in 0...floorSus + 2)
						{
							oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

							var sustainNote:Note = new Note(daStrumTime
								+ (Conductor.stepCrochet * susNote)
								+ (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2)), daNoteData,
								oldNote, true);
							sustainNote.mustPress = gottaHitNote;
							sustainNote.gfNote = (section.gfSection && (songNotes[1] < 4));
							sustainNote.noteType = swagNote.noteType;
							sustainNote.scrollFactor.set();

							unspawnNotes.push(sustainNote);

							if (sustainNote.mustPress)
								sustainNote.x += FlxG.width / 2;

							if (SaveData.get(OSU_MANIA_SIMULATION) && susLength < susNote)
								sustainNote.isLiftNote = true;
						}
					}

					swagNote.mustPress = gottaHitNote;

					if (swagNote.mustPress)
					{
						swagNote.x += FlxG.width / 2; // general offset
					}
				}
				else // THE FUCKING STUPID EVENT NOTES GOD
				{
					for (i in 0...songNotes[1].length)
					{
						var newEventNote:Array<Dynamic> = [songNotes[0], songNotes[1][i][0], songNotes[1][i][1], songNotes[1][i][2]];
						var subEvent:EventNote = {
							strumTime: newEventNote[0] + SaveData.get(NOTE_OFFSET),
							event: newEventNote[1],
							value1: newEventNote[2],
							value2: newEventNote[3]
						};
						subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
						eventNotes.push(subEvent);
						eventPushed(subEvent);
					}
				}
			}
			daBeats += 1;
		}

		for (event in SONG.events) // Event Notes
		{
			for (i in 0...event[1].length)
			{
				var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
				var subEvent:EventNote = {
					strumTime: newEventNote[0] + SaveData.get(NOTE_OFFSET),
					event: newEventNote[1],
					value1: newEventNote[2],
					value2: newEventNote[3]
				};
				subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
				eventNotes.push(subEvent);
				eventPushed(subEvent);
			}
		}

		unspawnNotes.sort(sortByShit);
		if (eventNotes.length > 1)
		{ // No need to sort if there's a single one or none at all
			eventNotes.sort(sortByTime);
		}
		checkEventNote();
		generatedMusic = true;
	}

	function eventPushed(event:EventNote)
	{
		switch (event.event)
		{
			case 'Change Character':
				var charType:Int = 0;
				switch (event.value1.toLowerCase())
				{
					case 'gf' | 'girlfriend' | '1':
						charType = 2;
					case 'dad' | 'opponent' | '0':
						charType = 1;
					default:
						charType = Std.parseInt(event.value1);
						if (Math.isNaN(charType)) charType = 0;
				}

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);
		}
	}

	function eventNoteEarlyTrigger(event:EventNote):Float
	{
		switch (event.event)
		{
			case 'Kill Henchmen': // Better timing so that the kill sound matches the beat intended
				return 280; // Plays 280ms before the actual position
		}
		return 0;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByTime(Obj1:EventNote, Obj2:EventNote):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				if (SONG.needsVoices)
					vocals.pause();
			}

			if (!startTimer.finished)
				startTimer.active = false;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = false;

			if (songSpeedTween != null)
				songSpeedTween.active = false;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars)
			{
				if (char != null && char.colorTween != null)
				{
					char.colorTween.active = false;
				}
			}
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (!startTimer.finished)
				startTimer.active = true;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = true;

			if (songSpeedTween != null)
				songSpeedTween.active = true;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars)
			{
				if (char != null && char.colorTween != null)
				{
					char.colorTween.active = true;
				}
			}
			paused = false;

			#if desktop
			if (startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, displaySongName
					+ " ("
					+ storyDifficultyText
					+ ")", uiHUD.iconP2.getCharacter(), true,
					songLength
					- Conductor.songPosition
					- SaveData.get(NOTE_OFFSET));
			}
			else
			{
				DiscordClient.changePresence(detailsText, displaySongName + " (" + storyDifficultyText + ")", uiHUD.iconP2.getCharacter());
			}
			#end
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
			{
				DiscordClient.changePresence(detailsText, displaySongName
					+ " ("
					+ storyDifficultyText
					+ ")", uiHUD.iconP2.getCharacter(), true,
					songLength
					- Conductor.songPosition
					- SaveData.get(NOTE_OFFSET));
			}
			else
			{
				DiscordClient.changePresence(detailsText, displaySongName + " (" + storyDifficultyText + ")", uiHUD.iconP2.getCharacter());
			}
		}
		#end

		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			DiscordClient.changePresence(detailsPausedText, displaySongName + " (" + storyDifficultyText + ")", uiHUD.iconP2.getCharacter());
		}
		#end

		if (SaveData.get(PAUSE_ON_FOCUS_LOST))
			openPauseMenu();

		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		if (finishTimer != null)
			return;

		if (SONG.needsVoices)
			vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		if (SONG.needsVoices)
		{
			vocals.time = Conductor.songPosition;
			vocals.play();
		}
	}

	private var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var limoSpeed:Float = 0;

	override public function update(elapsed:Float)
	{
		#if !debug
		perfectMode = false;
		#end

		if (!inCutscene)
		{
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
		}

		super.update(elapsed);

		if (cpuControlled)
		{
			botplaySine += 180 * elapsed;
			// assuming the text isnt null
			boyfriendStrums.botPlayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (controls.PAUSE #if android || FlxG.android.justReleased.BACK #end)
		{
			openPauseMenu();

			#if desktop
			DiscordClient.changePresence(detailsPausedText, displaySongName + " (" + storyDifficultyText + ")", uiHUD.iconP2.getCharacter());
			#end
		}

		if (health >= 2)
			health = 2;

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			Conductor.songPosition += FlxG.elapsed * 1000;

			if (!paused)
				if (Conductor.lastSongPos != Conductor.songPosition)
					Conductor.lastSongPos = Conductor.songPosition;
		}

		if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null)
		{
			var curSection = Std.int(curStep / 16);
			if (curSection != lastSection)
			{
				if (PlayState.SONG.notes[lastSection] != null)
				{
					var lastMustHit:Bool = PlayState.SONG.notes[lastSection].mustHitSection;
					if (SONG.notes[curSection].mustHitSection != lastMustHit)
					{
						camDisplaceX = 0;
						camDisplaceY = 0;
					}
					lastSection = Std.int(curStep / 16);
				}
			}

			updateCamFollow(elapsed);
		}

		if (camZooming)
		{
			// foreer stuff
			if (SaveData.get(SMOOTH_CAMERA_ZOOMS))
			{
				FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
				for (hud in allUIs)
					hud.zoom = FlxMath.lerp(1, hud.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
			}
			else
			{
				// this from kade - idk if there is a notable difference tbh
				FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, 0.95);
				for (hud in allUIs)
					hud.zoom = FlxMath.lerp(1, hud.zoom, 0.95);
			}
		}

		// add angle suppotr or ???

		FlxG.watch.addQuick("secShit", curSection);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);
		FlxG.watch.addQuick("bpmShit", Conductor.bpm);
		FlxG.watch.addQuick("speedShit", songSpeed);

		// RESET = Quick Game Over Screen
		if (controls.RESET && !SaveData.get(NO_RESET) && !inCutscene && !endingSong)
		{
			health = 0;
			trace("RESET = True");
		}

		doDeathCheck();

		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime;
			if (songSpeed < 1)
				time /= songSpeed;
			if (unspawnNotes[0].multSpeed < 1)
				time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				// add number of keys var
				strumLines.members[Math.floor((dunceNote.noteData + (dunceNote.mustPress ? 4 : 0)) / 4)].push(dunceNote);
				unspawnNotes.splice(unspawnNotes.indexOf(dunceNote), 1);
			}
		}

		noteCalls();
		checkEventNote();

		if (!inCutscene)
		{
			if (!cpuControlled)
			{
				keyShit();
			}
			else if (boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration
				&& boyfriend.animation.curAnim.name.startsWith('sing')
				&& !boyfriend.animation.curAnim.name.endsWith('miss'))
				boyfriend.dance();

			cameraDisplacement(boyfriend, true);
			cameraDisplacement(dad, false);
		}

		#if debug
		if (!endingSong && !startingSong)
		{
			if (FlxG.keys.justPressed.ONE)
				FlxG.sound.music.onComplete();
			if (FlxG.keys.justPressed.TWO)
			{ // Go 10 seconds into the future :O
				FlxG.sound.music.pause();
				vocals.pause();
				Conductor.songPosition += 10000;
				boyfriendStrums.allNotes.forEachAlive(function(daNote:Note)
				{
					if (daNote.strumTime + 800 < Conductor.songPosition)
						destroyNote(boyfriendStrums, daNote);
				});
				dadStrums.allNotes.forEachAlive(function(daNote:Note)
				{
					if (daNote.strumTime + 800 < Conductor.songPosition)
						destroyNote(dadStrums, daNote);
				});
				for (i in 0...unspawnNotes.length)
				{
					var daNote:Note = unspawnNotes[0];
					if (daNote.strumTime + 800 >= Conductor.songPosition)
					{
						break;
					}

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					unspawnNotes.splice(unspawnNotes.indexOf(daNote), 1);
					daNote.destroy();
				}

				FlxG.sound.music.time = Conductor.songPosition;
				FlxG.sound.music.play();

				vocals.time = Conductor.songPosition;
				vocals.play();
			}
		}
		#end
	}

	function noteCalls()
	{
		if (generatedMusic)
		{
			var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
			for (strumLine in strumLines)
			{
				strumLine.allNotes.forEachAlive(function(daNote:Note)
				{
					if (!daNote.mustPress && SaveData.get(MIDDLE_SCROLL))
					{
						daNote.active = true;
						daNote.visible = false;
					}
					else if (daNote.y > FlxG.height)
					{
						daNote.active = false;
						daNote.visible = false;
					}
					else
					{
						daNote.active = true;
						daNote.visible = true;
					}

					var strumGroup:StrumLine = boyfriendStrums;
					if (!daNote.mustPress)
						strumGroup = dadStrums;

					var strumX = strumGroup.receptors.members[daNote.noteData].x;
					var strumY = strumGroup.receptors.members[daNote.noteData].y;
					var strumAngle = strumGroup.receptors.members[daNote.noteData].angle;
					var strumDirection = strumGroup.receptors.members[daNote.noteData].direction;
					var strumAlpha = strumGroup.receptors.members[daNote.noteData].alpha;
					var strumScroll = strumGroup.receptors.members[daNote.noteData].downScroll;

					strumX += daNote.offsetX;
					strumY += daNote.offsetY;
					strumAngle += daNote.offsetAngle;
					strumAlpha *= daNote.multAlpha;

					if (strumScroll)
						daNote.distance = (0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed);
					else
						daNote.distance = (-0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed);

					var angleDir = strumDirection * Math.PI / 180;
					if (daNote.copyAngle)
						daNote.angle = strumDirection - 90 + strumAngle;

					if (daNote.copyAlpha)
						daNote.alpha = strumAlpha;

					if (daNote.copyX)
						daNote.x = strumX + Math.cos(angleDir) * daNote.distance;

					if (daNote.copyY)
					{
						daNote.y = strumY + Math.sin(angleDir) * daNote.distance;

						if (strumScroll && daNote.isSustainNote)
						{
							if (daNote.animation.curAnim.name.endsWith('end'))
							{
								daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * songSpeed + (46 * (songSpeed - 1));
								daNote.y -= 46 * (1 - (fakeCrochet / 600)) * songSpeed;
								if (isPixelStage)
									daNote.y += 8 + (6 - daNote.originalHeightForCalcs) * daPixelZoom;
								else
									daNote.y -= 19;
							}
							daNote.y += (Note.swagWidth / 2) - (60.5 * (songSpeed - 1));
							daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (songSpeed - 1);
						}
					}

					if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
					{
						opponentNoteHit(daNote);
					}

					if (daNote.mustPress && cpuControlled)
					{
						if (daNote.isSustainNote)
						{
							if (daNote.canBeHit)
							{
								goodNoteHit(daNote);
							}
						}
						else if (daNote.strumTime <= Conductor.songPosition
							|| (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress))
						{
							goodNoteHit(daNote);
						}
					}

					var center:Float = strumY + Note.swagWidth / 2;
					if (strumGroup.receptors.members[daNote.noteData].sustainReduce
						&& daNote.isSustainNote
						&& (daNote.mustPress || !daNote.ignoreNote)
						&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
					{
						if (strumScroll)
						{
							if (daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center)
							{
								var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
								swagRect.height = (center - daNote.y) / daNote.scale.y;
								swagRect.y = daNote.frameHeight - swagRect.height;

								daNote.clipRect = swagRect;
							}
						}
						else
						{
							if (daNote.y + daNote.offset.y * daNote.scale.y <= center)
							{
								var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
								swagRect.y = (center - daNote.y) / daNote.scale.y;
								swagRect.height -= swagRect.y;

								daNote.clipRect = swagRect;
							}
						}
					}

					if (Conductor.songPosition > noteKillOffset + daNote.strumTime)
					{
						if (daNote.mustPress && !cpuControlled && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit))
						{
							noteMiss(daNote);
						}

						destroyNote(strumGroup, daNote);
					}
				});
			}
		}
	}

	function destroyNote(strumline:StrumLine, daNote:Note)
	{
		daNote.active = false;
		daNote.exists = false;

		var chosenGroup = (daNote.isSustainNote ? strumline.holdsGroup : strumline.notesGroup);
		daNote.kill();
		if (strumline.allNotes.members.contains(daNote))
			strumline.allNotes.remove(daNote, true);
		if (chosenGroup.members.contains(daNote))
			chosenGroup.remove(daNote, true);
		daNote.destroy();
	}

	public var isDead:Bool = false;

	function doDeathCheck(?skipHealthCheck:Bool = false)
	{
		if ((skipHealthCheck || health <= 0) && !practiceMode && !isDead)
		{
			boyfriend.stunned = true;
			deathCounter++;

			persistentUpdate = false;
			persistentDraw = false;
			paused = true;

			camHUD.alpha = 0;
			camOther.alpha = 0;
			boyfriendGroup.alpha = 0;

			if (SONG.needsVoices)
				vocals.stop();
			FlxG.sound.music.stop();

			openSubState(new GameOverSubstate(boyfriend.x, boyfriend.y));

			#if desktop
			// Game Over doesn't get his own variable because it's only used here
			DiscordClient.changePresence("Game Over - " + detailsText, displaySongName + " (" + storyDifficultyText + ")", uiHUD.iconP2.getCharacter());
			#end
			isDead = true;
			return true;
		}
		return false;
	}

	public function checkEventNote()
	{
		while (eventNotes.length > 0)
		{
			var leStrumTime:Float = eventNotes[0].strumTime;
			if (Conductor.songPosition < leStrumTime)
			{
				break;
			}

			var value1:String = '';
			if (eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if (eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			triggerEventNote(eventNotes[0].event, value1, value2);
			eventNotes.shift();
		}
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String, ?onLua:Bool = false)
	{
		switch (eventName)
		{
			case 'Hey!':
				var value:Int = Std.parseInt(value1);
				var time:Float = Std.parseFloat(value2);
				if (Math.isNaN(time) || time <= 0)
					time = 0.6;

				if (value != 0)
				{
					if (dad.curCharacter == 'gf')
					{ // Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = time;
					}
					else
					{
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = time;
					}
				}
				if (value != 1)
				{
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = time;
				}

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if (Math.isNaN(value))
					value = 1;
				gfSpeed = value;

			
			case 'Add Camera Zoom':
				if (SaveData.get(CAMERA_ZOOMS) && FlxG.camera.zoom < 1.35)
				{
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if (Math.isNaN(camZoom))
						camZoom = 0.015;
					if (Math.isNaN(hudZoom))
						hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					for (hud in allUIs)
						hud.zoom += hudZoom;
				}

			case 'Change Scroll Speed':
				if (songSpeedType == "constant")
					return;
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if (Math.isNaN(val1))
					val1 = 1;
				if (Math.isNaN(val2))
					val2 = 0;

				var newValue:Float = SONG.speed * SaveData.getGameplaySetting('scrollspeed', 1) * val1;

				if (val2 <= 0)
				{
					songSpeed = newValue;
				}
				else
				{
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2, {
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween)
						{
							songSpeedTween = null;
						}
					});
				}

			case 'Play Animation':
				trace('Anim to play: ' + value1);
				var val2:Int = Std.parseInt(value2);
				if (Math.isNaN(val2))
					val2 = 0;

				var char:Character = dad;
				switch (val2)
				{
					case 1: char = boyfriend;
					case 2: char = gf;
				}
				char.playAnim(value1, true);
				char.specialAnim = true;

			case 'Camera Follow Pos':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if (Math.isNaN(val1))
					val1 = 0;
				if (Math.isNaN(val2))
					val2 = 0;

				isCameraOnForcedPos = false;
				if (!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2)))
				{
					camFollow.x = val1;
					camFollow.y = val2;
					isCameraOnForcedPos = true;
				}

			case 'Alt Idle Animation':
				var val:Int = Std.parseInt(value1);
				if (Math.isNaN(val))
					val = 0;

				var char:Character = dad;
				switch (val)
				{
					case 1: char = boyfriend;
					case 2: char = gf;
				}
				char.idleSuffix = value2;
				char.recalculateDanceIdle();

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length)
				{
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = Std.parseFloat(split[0].trim());
					var intensity:Float = Std.parseFloat(split[1].trim());
					if (Math.isNaN(duration))
						duration = 0;
					if (Math.isNaN(intensity))
						intensity = 0;

					if (duration > 0 && intensity != 0)
					{
						targetsArray[i].shake(intensity, duration);
					}
				}

			case 'Change Character':
				var charType:Int = 0;
				switch (value1)
				{
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if (Math.isNaN(charType)) charType = 0;
				}

				switch (charType)
				{
					case 0:
						if (boyfriend.curCharacter != value2)
						{
							if (!boyfriendMap.exists(value2))
							{
								addCharacterToList(value2, charType);
							}

							boyfriend.visible = false;
							boyfriend = boyfriendMap.get(value2);
							if (!boyfriend.alreadyLoaded)
							{
								boyfriend.alpha = 1;
								boyfriend.alreadyLoaded = true;
							}
							boyfriend.visible = true;
							uiHUD.iconP1.changeIcon(boyfriend.healthIcon);
						}

					case 1:
						if (dad.curCharacter != value2)
						{
							if (!dadMap.exists(value2))
							{
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf');
							dad.visible = false;
							dad = dadMap.get(value2);
							if (!dad.curCharacter.startsWith('gf'))
							{
								if (wasGf)
								{
									gf.visible = true;
								}
							}
							else
							{
								gf.visible = false;
							}
							if (!dad.alreadyLoaded)
							{
								dad.alpha = 1;
								dad.alreadyLoaded = true;
							}
							dad.visible = true;
							uiHUD.iconP2.changeIcon(dad.healthIcon);
						}

					case 2:
						if (gf.curCharacter != value2)
						{
							if (!gfMap.exists(value2))
							{
								addCharacterToList(value2, charType);
							}

							var isGfVisible:Bool = gf.visible;
							gf.visible = false;
							gf = gfMap.get(value2);
							if (!gf.alreadyLoaded)
							{
								gf.alpha = 1;
								gf.alreadyLoaded = true;
							}
							gf.visible = isGfVisible;
						}
				}
		}
	}

	function snapCamFollowToPos(x:Float, y:Float)
	{
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	function finishSong():Void
	{
		var finishCallback:Void->Void = endSong; // In case you want to change it in a specific song.

		FlxG.sound.music.volume = 0;
		if (SONG.needsVoices)
		{
			vocals.volume = 0;
			vocals.pause();
		}
		if (SaveData.get(NOTE_OFFSET) <= 0)
		{
			finishCallback();
		}
		else
		{
			finishTimer = new FlxTimer().start(SaveData.get(NOTE_OFFSET) / 1000, function(tmr:FlxTimer)
			{
				finishCallback();
			});
		}
	}

	public var transitioning = false;

	function endSong():Void
	{
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;

		deathCounter = 0;
		seenCutscene = false;
		KillNotes();

		var practice = SaveData.getGameplaySetting('practice', false);
		var botplay = SaveData.getGameplaySetting('botplay', false);

		if (!transitioning)
		{
			if (SONG.validScore && practice == false && botplay == false)
			{
				#if !switch
				var percent:Float = ratingPercent;
				if (Math.isNaN(percent))
					percent = 0;
				Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
				#end
			}

			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					FlxG.sound.playMusic(Paths.music('freakyMenu'));

					if (FlxTransitionableState.skipNextTransIn)
						CustomFadeTransition.nextCamera = null;

					MusicBeatState.switchState(new StoryMenuState());

					if (practice == false && cpuControlled == false)
					{
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);

						if (SONG.validScore)
							Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);

						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
				}
				else
				{
					var diff:String = CoolUtil.getDifficultyFilePath();
					var next = Paths.formatToSongPath(PlayState.storyPlaylist[0]);

					trace('loading next song', next + diff);

					var winterHorrorNext = (Paths.formatToSongPath(SONG.song) == "eggnog");
					if (winterHorrorNext)
					{
						var black:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
							-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
						black.scrollFactor.set();
						add(black);
						camHUD.visible = false;

						FlxG.sound.play(Paths.sound('Lights_Shut_off'));
					}

					prevCamFollow = camFollow;
					prevCamFollowPos = camFollowPos;

					PlayState.SONG = Song.loadFromJson(next + diff, next);
					PlayState.instSource = null;
					PlayState.voicesSource = null;
					System.gc();
					FlxG.sound.music.stop();

					if (winterHorrorNext)
					{
						new FlxTimer().start(1.5, function(tmr:FlxTimer)
						{
							LoadingState.loadAndSwitchState(new PlayState());
						});
					}
					else
						LoadingState.loadAndSwitchState(new PlayState());
				}
			}
			else
			{
				if (FlxTransitionableState.skipNextTransIn)
					CustomFadeTransition.nextCamera = null;

				MusicBeatState.switchState(new FreeplayState());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
			}
			transitioning = true;
		}
	}

	private function KillNotes()
	{
		while (dadStrums.allNotes.length > 0)
		{
			destroyNote(dadStrums, dadStrums.allNotes.members[0]);
		}

		while (boyfriendStrums.allNotes.length > 0)
		{
			destroyNote(boyfriendStrums, boyfriendStrums.allNotes.members[0]);
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	private var createdColor = FlxColor.fromRGB(204, 66, 66);

	private function popUpCombo()
	{
		var comboString:String = Std.string(combo);
		var negative:Bool = false;
		if (comboString.startsWith("-") || combo == 0)
			negative = true;
		var stringArray:Array<String> = comboString.split("");

		if (lastScore != null)
		{
			while (lastScore.length > 0)
			{
				lastScore[0].kill();
				lastScore.remove(lastScore[0]);
			}
		}

		for (scoreInt in 0...stringArray.length)
		{
			var numScore:FlxSprite = Ratings.generateCombo(stringArray[scoreInt], (!negative ? ratingFC.contains("SFC") : false), negative,
				createdColor, scoreInt);

			if (!SaveData.get(COMBO_STACKING))
				lastScore.push(numScore);

			add(numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.001
			});

			numScore.cameras = [camHUD];
		}
	}

	private function displayRating(daRating:String, timing:String)
	{
		var rating = Ratings.generateRating('$daRating', (daRating == "sick" ? ratingFC.contains("SFC") : false), timing);
		add(rating);

		if (!SaveData.get(COMBO_STACKING))
		{
			if (lastRating != null)
				lastRating.kill();
			lastRating = rating;
		}

		add(rating);
		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.00125
		});

		rating.cameras = [camHUD];
	}

	private function popUpScore(daNote:Note = null, timing:String)
	{
		var noteDiff:Float = Math.abs(daNote.strumTime - Conductor.songPosition + SaveData.get(RATING_OFFSET));
		if (SONG.needsVoices)
			vocals.volume = 1;

		var score:Int = 350;
		var daRating = Ratings.judgeNote(noteDiff);

		// look into this
		if (daRating == "miss")
		{
			noteMiss(daNote);
			return;
		}

		var judgementInfo = Ratings.judgementsMap.get(daRating);
		score = judgementInfo[2];
		totalNotesHit += judgementInfo[3];
		songScore += score;

		daNote.ratingMod = judgementInfo[3];
		daNote.rating = daRating;

		// make it more dynamic?
		switch (daRating)
		{
			case "shit":
				combo = 0;
				songMisses++;
				health -= 0.2;
				if (!daNote.ratingDisabled)
					shits++;
			case "bad":
				health -= 0.06;
				if (!daNote.ratingDisabled)
					bads++;
			case "good":
				if (!daNote.ratingDisabled)
					goods++;
			case "sick":
				if (!daNote.ratingDisabled)
					sicks++;
		}

		if (daRating == "sick" && !daNote.noteSplashDisabled)
			spawnNoteSplashOnNote(daNote);

		if (!daNote.ratingDisabled)
		{
			songHits++;
			updateAccuracy(false);
		}

		if (SaveData.get(SCORE_ZOOM))
			if (!cpuControlled)
				uiHUD.doScoreZoom();

		displayRating(daRating, timing);
		popUpCombo();
	}

	private function keyShit():Void
	{
		if (SaveData.get(INPUT_TYPE) == "Kade 1.5.3")
		{
			var holdArray:Array<Bool> = [controls.NOTE_LEFT, controls.NOTE_DOWN, controls.NOTE_UP, controls.NOTE_RIGHT];
			var controlArray:Array<Bool> = [
				controls.NOTE_LEFT_P,
				controls.NOTE_DOWN_P,
				controls.NOTE_UP_P,
				controls.NOTE_RIGHT_P
			];
			var releaseArray:Array<Bool> = [
				controls.NOTE_LEFT_R,
				controls.NOTE_DOWN_R,
				controls.NOTE_UP_R,
				controls.NOTE_RIGHT_R
			];

			if (!boyfriend.stunned && generatedMusic)
			{
				if (controlArray.contains(true))
				{
					boyfriend.holdTimer = 0;

					var possibleNotes:Array<Note> = [];
					var directionList:Array<Int> = [];
					var dumbNotes:Array<Note> = [];

					boyfriendStrums.allNotes.forEachAlive(function(daNote:Note)
					{
						if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isLiftNote)
						{
							if (directionList.contains(daNote.noteData))
							{
								for (coolNote in possibleNotes)
								{
									if (coolNote.noteData == daNote.noteData && Math.abs(daNote.strumTime - coolNote.strumTime) < 10)
									{
										dumbNotes.push(daNote);
										break;
									}
									else if (coolNote.noteData == daNote.noteData && daNote.strumTime < coolNote.strumTime)
									{
										possibleNotes.remove(coolNote);
										possibleNotes.push(daNote);
										break;
									}
								}
							}
							else
							{
								possibleNotes.push(daNote);
								directionList.push(daNote.noteData);
							}
						}
					});

					for (note in dumbNotes)
					{
						FlxG.log.add("killing dumb ass note at " + note.strumTime);
						destroyNote(boyfriendStrums, note);
					}

					possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

					var dontCheck = false;

					for (i in 0...controlArray.length)
					{
						if (controlArray[i] && !directionList.contains(i))
							dontCheck = true;
					}

					if (possibleNotes.length > 0 && !dontCheck)
					{
						if (!SaveData.get(GHOST_TAPPING))
						{
							for (shit in 0...controlArray.length)
							{
								if (controlArray[shit] && !directionList.contains(shit))
									noteMissPress(shit);
							}
						}

						for (coolNote in possibleNotes)
						{
							if (controlArray[coolNote.noteData] && coolNote.canBeHit && !coolNote.tooLate)
							{
								if (mashViolations != 0)
									mashViolations--;
								uiHUD.scoreTxt.color = FlxColor.WHITE;
								goodNoteHit(coolNote);
							}
						}
					}
					else if (!SaveData.get(GHOST_TAPPING))
					{
						for (shit in 0...controlArray.length)
						{
							if (controlArray[shit] && !directionList.contains(shit))
								noteMissPress(shit);
						}
					}

					if (dontCheck && possibleNotes.length > 0)
					{
						if (mashViolations > 4)
						{
							FlxG.log.add("mash violations " + mashViolations);
							uiHUD.scoreTxt.color = FlxColor.RED;
							for (shit in 0...controlArray.length)
							{
								noteMissPress(shit);
							}
						}
						else
							mashViolations++;
					}
				}

				if (releaseArray.contains(true) && SaveData.get(OSU_MANIA_SIMULATION))
				{
					boyfriend.holdTimer = 0;

					var possibleNotes:Array<Note> = [];
					var directionList:Array<Int> = [];
					var dumbNotes:Array<Note> = [];

					boyfriendStrums.allNotes.forEachAlive(function(daNote:Note)
					{
						if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && daNote.isLiftNote)
						{
							if (directionList.contains(daNote.noteData))
							{
								for (coolNote in possibleNotes)
								{
									if (coolNote.noteData == daNote.noteData && Math.abs(daNote.strumTime - coolNote.strumTime) < 10)
									{
										dumbNotes.push(daNote);
										break;
									}
									else if (coolNote.noteData == daNote.noteData && daNote.strumTime < coolNote.strumTime)
									{
										possibleNotes.remove(coolNote);
										possibleNotes.push(daNote);
										break;
									}
								}
							}
							else
							{
								possibleNotes.push(daNote);
								directionList.push(daNote.noteData);
							}
						}
					});

					for (note in dumbNotes)
					{
						FlxG.log.add("killing dumb ass note at (release arr) " + note.strumTime);
						destroyNote(boyfriendStrums, note);
					}

					possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

					var dontCheck = false;

					for (i in 0...releaseArray.length)
					{
						if (releaseArray[i] && !directionList.contains(i))
							dontCheck = true;
					}

					if (possibleNotes.length > 0 && !dontCheck)
					{
						for (coolNote in possibleNotes)
						{
							if (releaseArray[coolNote.noteData])
							{
								if (mashViolations != 0)
									mashViolations--;
								uiHUD.scoreTxt.color = FlxColor.WHITE;
								goodNoteHit(coolNote, true);
							}
						}
					}

					if (dontCheck && possibleNotes.length > 0)
					{
						if (mashViolations > 4)
						{
							FlxG.log.add("mash violations " + mashViolations);
							uiHUD.scoreTxt.color = FlxColor.RED;
							for (shit in 0...releaseArray.length)
							{
								noteMissPress(shit);
							}
						}
						else
							mashViolations++;
					}
				}

				if (holdArray.contains(true))
				{
					boyfriendStrums.allNotes.forEachAlive(function(daNote:Note)
					{
						if (daNote.canBeHit && daNote.mustPress && daNote.isSustainNote && holdArray[daNote.noteData] && !daNote.isLiftNote)
							goodNoteHit(daNote);
					});
				}
			}

			boyfriendStrums.allNotes.forEachAlive(function(daNote:Note)
			{
				// rip strumline
				if (SaveData.get(DOWN_SCROLL) && daNote.y > 50 || !SaveData.get(DOWN_SCROLL) && daNote.y < 50)
				{
					// Force good note hit regardless if it's too late to hit it or not as a fail safe
					if (cpuControlled && daNote.canBeHit && daNote.mustPress || cpuControlled && daNote.tooLate && daNote.mustPress)
					{
						goodNoteHit(daNote);
						boyfriend.holdTimer = daNote.sustainLength;
					}
				}
			});

			if (boyfriend.holdTimer > Conductor.stepCrochet * 4 * 0.001 && (!holdArray.contains(true) || cpuControlled))
			{
				if (boyfriend.animation.curAnim.name.startsWith("sing") && !boyfriend.animation.curAnim.name.endsWith("miss"))
					boyfriend.playAnim('idle');
			}

			boyfriendStrums.receptors.forEach(function(spr:UIStaticArrow)
			{
				if (controlArray[spr.ID] && spr.animation.curAnim.name != "confirm")
				{
					spr.playAnim('pressed');
					spr.resetAnim = 0;
					funkyFreestyle(spr.ID);
				}

				if (releaseArray[spr.ID])
				{
					spr.playAnim('static');
					spr.resetAnim = 0;
				}
			});
		}
		else if (SaveData.get(INPUT_TYPE) == "Psych 0.4.2")
		{
			// HOLDING
			var up = controls.NOTE_UP;
			var right = controls.NOTE_RIGHT;
			var down = controls.NOTE_DOWN;
			var left = controls.NOTE_LEFT;

			var upP = controls.NOTE_UP_P;
			var rightP = controls.NOTE_RIGHT_P;
			var downP = controls.NOTE_DOWN_P;
			var leftP = controls.NOTE_LEFT_P;

			var upR = controls.NOTE_UP_R;
			var rightR = controls.NOTE_RIGHT_R;
			var downR = controls.NOTE_DOWN_R;
			var leftR = controls.NOTE_LEFT_R;

			var controlArray:Array<Bool> = [leftP, downP, upP, rightP];
			var controlReleaseArray:Array<Bool> = [leftR, downR, upR, rightR];
			var controlHoldArray:Array<Bool> = [left, down, up, right];

			if (!boyfriend.stunned && generatedMusic)
			{
				// rewritten inputs???
				boyfriendStrums.allNotes.forEachAlive(function(daNote:Note)
				{
					// hold note functions
					if (daNote.isSustainNote && controlHoldArray[daNote.noteData] && daNote.canBeHit && daNote.mustPress && !daNote.tooLate
						&& !daNote.wasGoodHit)
					{
						goodNoteHit(daNote);
					}
				});

				if ((controlHoldArray.contains(true) || controlArray.contains(true)) && !endingSong)
				{
					var canMiss:Bool = !SaveData.get(GHOST_TAPPING);
					if (controlArray.contains(true))
					{
						for (i in 0...controlArray.length)
						{
							// heavily based on my own code LOL if it aint broke dont fix it
							var pressNotes:Array<Note> = [];
							var notesStopped:Bool = false;

							var sortedNotesList:Array<Note> = [];
							boyfriendStrums.allNotes.forEachAlive(function(daNote:Note)
							{
								if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && daNote.noteData == i)
								{
									sortedNotesList.push(daNote);
									canMiss = true;
								}
							});
							sortedNotesList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

							if (sortedNotesList.length > 0)
							{
								for (epicNote in sortedNotesList)
								{
									for (doubleNote in pressNotes)
									{
										if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 10)
										{
											destroyNote(boyfriendStrums, doubleNote);
										}
										else
											notesStopped = true;
									}

									// eee jack detection before was not super good
									if (controlArray[epicNote.noteData] && !notesStopped)
									{
										goodNoteHit(epicNote);
										pressNotes.push(epicNote);
									}
								}
							}
							else if (canMiss)
							{
								if (controlArray[i])
								{
									noteMissPress(i);
								}
							}
						}
					}
				}
				else if (boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration
					&& boyfriend.animation.curAnim.name.startsWith('sing')
					&& !boyfriend.animation.curAnim.name.endsWith('miss'))
				{
					boyfriend.dance();
				}
			}

			boyfriendStrums.receptors.forEach(function(spr:UIStaticArrow)
			{
				if (controlArray[spr.ID] && spr.animation.curAnim.name != "confirm")
				{
					spr.playAnim('pressed');
					spr.resetAnim = 0;
					funkyFreestyle(spr.ID);
				}

				if (controlReleaseArray[spr.ID])
				{
					spr.playAnim('static');
					spr.resetAnim = 0;
				}
			});
		}
	}

	// change it back to char instead of ujsing strum chars
	function noteMiss(daNote:Note):Void
	{
		if (!boyfriend.stunned)
		{
			boyfriendStrums.allNotes.forEachAlive(function(note:Note)
			{
				if (daNote != note
					&& daNote.mustPress
					&& daNote.noteData == note.noteData
					&& daNote.isSustainNote == note.isSustainNote
					&& Math.abs(daNote.strumTime - note.strumTime) < 10)
				{
					destroyNote(boyfriendStrums, note);
				}
			});

			switch (daNote.noteType)
			{
				default:
					health -= daNote.missHealth * healthLoss;
					if (instakillOnMiss)
					{
						if (SONG.needsVoices)
							vocals.volume = 0;
						doDeathCheck(true);
					}

					decreaseCombo();

					if (SONG.needsVoices)
						vocals.volume = 0;

					var char:Character = boyfriend;
					if (daNote.gfNote)
						char = gf;

					if (char != null && char.hasMissAnimations)
					{
						var daAlt = '';
						if (daNote.noteType == "Alt Animation")
							daAlt = '-alt';

						char.playAnim(singAnims[Std.int(Math.abs(daNote.noteData)) % 4] + "miss" + daAlt, true);
					}

					if (SaveData.get(MISS_VOL) > 0)
						FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), SaveData.get(MISS_VOL));

					updateAccuracy();
			}
		}
	}

	function noteMissPress(direction:Int = 1):Void
	{
		if (!boyfriend.stunned)
		{
			health -= 0.05 * healthLoss;
			if (instakillOnMiss)
			{
				if (SONG.needsVoices)
					vocals.volume = 0;
				doDeathCheck(true);
			}

			decreaseCombo();

			if (SONG.needsVoices)
				vocals.volume = 0;

			if (boyfriend != null && boyfriend.hasMissAnimations)
				boyfriend.playAnim(singAnims[direction] + "miss", true);

			if (SaveData.get(MISS_VOL) > 0)
				FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), SaveData.get(MISS_VOL));

			updateAccuracy();
		}
	}

	function goodNoteHit(note:Note, released:Bool = false):Void // i hate myself
	{
		var timing = "";

		if (!note.wasGoodHit)
		{
			if (SaveData.get(HITSOUND_VOL) > 0 && !note.hitsoundDisabled)
				FlxG.sound.play(Paths.sound('hitsound'), SaveData.get(HITSOUND_VOL));

			if (!note.ratingDisabled)
			{
				if (note.strumTime < Conductor.songPosition + SaveData.get(RATING_OFFSET))
					timing = "late";
				else
					timing = "early";
			}

			if (!note.isSustainNote || released && note.isLiftNote)
			{
				increaseCombo();
				popUpScore(note, timing);
				if (combo > 9999)
					combo = 9999;
			}
			else if (note.isSustainNote)
				totalNotesHit++;

			health += note.hitHealth * healthGain;

			if (!note.noAnimation)
			{
				var char:Character = boyfriend;
				var daAlt = '';
				if (note.noteType == "Alt Animation")
					daAlt = '-alt';

				if (note.gfNote)
					char = gf;

				if (char != null && !(released && note.isLiftNote))
				{
					char.playAnim(singAnims[Std.int(Math.abs(note.noteData)) % 4] + daAlt, true);
					char.holdTimer = 0;
				}

				if (note.noteType == "Hey!")
				{
					if (boyfriend.animOffsets.exists('hey'))
					{
						boyfriend.playAnim('hey', true);
						boyfriend.specialAnim = true;
						boyfriend.heyTimer = 0.6;
					}

					if (gf != null && gf.animOffsets.exists('cheer'))
					{
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = 0.6;
					}
				}
			}

			if (cpuControlled)
			{
				var time:Float = 0.15;
				if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
					time += 0.15;
				StrumPlayAnim(false, Std.int(Math.abs(note.noteData)) % 4, time);
			}
			else
			{
				boyfriendStrums.receptors.forEach(function(spr:UIStaticArrow)
				{
					if (Math.abs(note.noteData) == spr.ID)
						spr.playAnim('confirm', true);
				});
			}

			note.wasGoodHit = true;
			if (SONG.needsVoices)
				vocals.volume = 1;

			if (!note.isSustainNote)
			{
				if (cpuControlled)
					boyfriend.holdTimer = 0;
				destroyNote(boyfriendStrums, note);
			}
			else if (cpuControlled)
			{
				var targetHold:Float = Conductor.stepCrochet * 0.001 * boyfriend.singDuration;
				if (boyfriend.holdTimer + 0.2 > targetHold)
					boyfriend.holdTimer = targetHold - 0.2;
			}

			updateAccuracy();
		}
	}

	function opponentNoteHit(note:Note):Void
	{
		if (note.noteType == 'Hey!' && dad.animOffsets.exists('hey'))
		{
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = 0.6;
		}
		else if (note.noteType == 'Hey!' && boyfriend.animOffsets.exists('hey'))
		{
			boyfriend.playAnim('hey', true);
			boyfriend.specialAnim = true;
			boyfriend.heyTimer = 0.6;
		}
		else if (!note.noAnimation)
		{
			var altAnim:String = "";

			var curSection:Int = Math.floor(curStep / 16);
			if (SONG.notes[curSection] != null)
			{
				if (SONG.notes[curSection].altAnim || note.noteType == 'Alt Animation')
					altAnim = '-alt';
			}

			var char:Character = dad;

			if (note.gfNote)
				char = gf;

			if (char != null)
			{
				char.playAnim(singAnims[Std.int(Math.abs(note.noteData)) % 4] + altAnim, true);
				char.holdTimer = 0;
			}
		}

		if (SONG.needsVoices)
			vocals.volume = 1;

		var time:Float = 0.15;
		if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
			time += 0.15;
		StrumPlayAnim(true, Std.int(Math.abs(note.noteData)) % 4, time);
		note.hitByOpponent = true;

		if (!note.isSustainNote)
		{
			if (!SaveData.get(MIDDLE_SCROLL) && SaveData.get(OPPONENT_NOTE_SPLASHES))
				spawnNoteSplashOnNote(note, true);
			destroyNote(dadStrums, note);
		}
	}

	function spawnNoteSplashOnNote(note:Note, isDad:Bool = false)
	{
		if (SaveData.get(NOTE_SPLASHES) && note != null)
		{
			var strum:StrumLine = null;
			if (isDad)
				strum = dadStrums;
			else
				strum = boyfriendStrums;

			if (strum != null)
				strum.createSplash(note.noteData, note);
		}
	}

	override function destroy()
	{
		super.destroy();
	}

	var lastStepHit:Int = -1;

	override function stepHit()
	{
		super.stepHit();
		if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > 20
			|| (SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > 20))
		{
			resyncVocals();
		}

		if (curStep == lastStepHit)
		{
			return;
		}

		lastStepHit = curStep;
	}

	var lastBeatHit:Int = -1;

	override function beatHit()
	{
		super.beatHit();

		if (lastBeatHit >= curBeat)
		{
			trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		// you might ask, why not just use uiHUD.iconPX? i dont know
		uiHUD.beatHit();

		if (gf != null
			&& curBeat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0
			&& !gf.stunned
			&& gf.animation.curAnim.name != null
			&& !gf.animation.curAnim.name.startsWith("sing")
			&& !gf.stunned)
		{
			// taken from the pe-0.4.2 android thingy
			if (SaveData.get(ICON_BOPING))
			{
				if (curBeat % gfSpeed == 0)
				{
					curBeat % (gfSpeed * 2) == 0 ? {
						uiHUD.iconP1.scale.set(1.1, 0.8);
						uiHUD.iconP2.scale.set(1.1, 1.3);

						FlxTween.angle(uiHUD.iconP1, -15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
						FlxTween.angle(uiHUD.iconP2, 15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
					} : {
						uiHUD.iconP1.scale.set(1.1, 1.3);
						uiHUD.iconP2.scale.set(1.1, 0.8);

						FlxTween.angle(uiHUD.iconP2, -15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
						FlxTween.angle(uiHUD.iconP1, 15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
						}

					FlxTween.tween(uiHUD.iconP1, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});
					FlxTween.tween(uiHUD.iconP2, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});

					uiHUD.iconP1.updateHitbox();
					uiHUD.iconP2.updateHitbox();
				}
			}
			gf.dance();
		}
		if (curBeat % boyfriend.danceEveryNumBeats == 0
			&& boyfriend.animation.curAnim != null
			&& !boyfriend.animation.curAnim.name.startsWith('sing')
			&& !boyfriend.stunned)
		{
			boyfriend.dance();
		}
		if (curBeat % dad.danceEveryNumBeats == 0
			&& dad.animation.curAnim != null
			&& !dad.animation.curAnim.name.startsWith('sing')
			&& !dad.stunned)
		{
			dad.dance();
		}

		lastBeatHit = curBeat;
	}

	override function sectionHit()
	{
		super.sectionHit();

		if (SONG.notes[curSection] != null)
		{
			if (camZooming && FlxG.camera.zoom < 1.35 && SaveData.get(CAMERA_ZOOMS) && curBeat % 4 == 0)
			{
				FlxG.camera.zoom += 0.015;
				for (hud in allUIs)
					hud.zoom += 0.05;
			}

			if (SONG.notes[curSection].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[curSection].bpm);

				if (songSpeedType == "constant")
					return;
				var baseSpeed = SONG.speed * SaveData.getGameplaySetting('scrollspeed', 1);
				var newSpeed = baseSpeed + (baseSpeed * ((Conductor.bpm / SONG.bpm) / 10));
				songSpeed = newSpeed;
			}
		}
	}

	function StrumPlayAnim(isDad:Bool, id:Int, time:Float)
	{
		var spr:UIStaticArrow = null;
		if (isDad)
			spr = dadStrums.receptors.members[id];
		else
			spr = boyfriendStrums.receptors.members[id];

		if (spr != null)
		{
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public var ratingString:String;
	public var ratingPercent:Float;
	public var ratingFC:String;

	public function RecalculateRating()
	{
		if (totalPlayed < 1)
		{
			switch (SaveData.get(SCORE_TEXT_STYLE))
			{
				case 'Engine' | 'Forever':
					ratingString = "N/A";
				case 'Psych':
					ratingString = "?";
			}
		}
		else
		{
			if (ratingPercent >= 1)
			{
				ratingString = ratingStuff[ratingStuff.length - 1][0];
			}
			else
			{
				for (i in 0...ratingStuff.length - 1)
				{
					if (ratingPercent < ratingStuff[i][1])
					{
						ratingString = ratingStuff[i][0];
						break;
					}
				}
			}
		}

		ratingFC = "";
		if (sicks > 0)
			ratingFC = "SFC";
		if (goods > 0)
			ratingFC = "GFC";
		if (bads > 0 || shits > 0)
			ratingFC = "FC";
		if (songMisses > 0 && songMisses < 10)
			ratingFC = "SDCB";
		else if (songMisses >= 10)
			ratingFC = "Clear";
	}

	// no way is this from sonic.exe v2.5?????¿?¿?!?!?!??!?=?=?=?!?!1
	var camDisp:Float = 8;

	function cameraDisplacement(character:Character, mustHit:Bool)
	{
		if (SaveData.get(CAMERA_MOVEMENT))
		{
			if (SONG.notes[Std.int(curStep / 16)] != null)
			{
				if (SONG.notes[Std.int(curStep / 16)].mustHitSection
					&& mustHit
					|| (!SONG.notes[Std.int(curStep / 16)].mustHitSection && !mustHit))
				{
					if (character.animation.curAnim != null)
					{
						camDisplaceX = 0;
						camDisplaceY = 0;
						switch (character.animation.curAnim.name)
						{
							case 'singUP':
								camDisplaceY -= camDisp;
							case 'singDOWN':
								camDisplaceY += camDisp;
							case 'singLEFT':
								camDisplaceX -= camDisp;
							case 'singRIGHT':
								camDisplaceX += camDisp;

							// funky - move to the opposite direction as it missed, would be cool to get the note direction to move in that direction lol
							case 'singUPmiss':
								camDisplaceY += camDisp;
							case "singDOWNmiss":
								camDisplaceY -= camDisp;
							case "singLEFTmiss":
								camDisplaceX += camDisp;
							case "singRIGHTmiss":
								camDisplaceX -= camDisp;
						}
					}
				}
			}
		}
	}

	function updateCamFollow(?elapsed:Float)
	{
		if (elapsed == null)
			elapsed = FlxG.elapsed;
		if (!PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection)
		{
			var char = dad;

			var getCenterX = char.getMidpoint().x + 150;
			var getCenterY = char.getMidpoint().y - 100;

			camFollow.set(getCenterX, getCenterY);

			camFollow.x += camDisplaceX + char.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += camDisplaceY + char.cameraPosition[1] + opponentCameraOffset[1];
		}
		else
		{
			var char = boyfriend;

			var getCenterX = char.getMidpoint().x - 100;
			var getCenterY = char.getMidpoint().y - 100;

			camFollow.set(getCenterX, getCenterY);

			camFollow.x += camDisplaceX - char.cameraPosition[0] + boyfriendCameraOffset[0];
			camFollow.y += camDisplaceY + char.cameraPosition[1] + boyfriendCameraOffset[1];
		}
	}

	// goofy fix for the cutscene camera
	function focusCamera(isDad:Bool = false)
	{
		if (isDad)
		{
			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
		}
		else
		{
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];
		}
	}

	function funkyFreestyle(direction:Int)
	{
		if (SaveData.get(GHOST_TAPPING) && !cpuControlled && SaveData.get(FREESTYLE_BF) && !boyfriend.specialAnim)
		{
			boyfriend.playAnim(singAnims[direction]);
		}
	}

	function precache()
	{
		// precache if vol higher than 0
		if (SaveData.get(MISS_VOL) > 0)
		{
			CoolUtil.precacheSound('missnote1');
			CoolUtil.precacheSound('missnote2');
			CoolUtil.precacheSound('missnote3');
		}

		if (SaveData.get(HITSOUND_VOL) > 0)
			CoolUtil.precacheSound('hitsound');

		if (PauseSubState.songName != null)
			CoolUtil.precacheMusic(PauseSubState.songName);
		else if (SaveData.get(PAUSE_MUSIC) != null)
			CoolUtil.precacheMusic(Paths.formatToSongPath(SaveData.get(PAUSE_MUSIC)));

		// cache them
		Paths.getGraphic(Paths.getLibraryPath('${SaveData.get(COMBOS_STYLE)}/combo.png', "UILib"));
		Paths.getGraphic(Paths.getLibraryPath('${SaveData.get(RATINGS_STYLE)}/judgements.png', "UILib"));
	}

	function updateAccuracy(incrementTP:Bool = true)
	{
		if (incrementTP)
			totalPlayed++;
		ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
		RecalculateRating();
	}

	function openPauseMenu()
	{
		if (!paused && startedCountdown && canPause && !inCutscene)
		{
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				if (SONG.needsVoices)
					vocals.pause();
			}
			openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		}
	}

	function decreaseCombo()
	{
		if (combo > 0)
			combo = 0;
		else
			combo--;

		if (!practiceMode)
			songScore -= 5;
		if (!endingSong)
		{
			songMisses++;
			songScore -= 15;
			totalNotesHit -= 1;
		}

		displayRating("miss", "late");
		popUpCombo();
	}

	// wtf
	function increaseCombo()
	{
		if (combo < 0)
			combo = 0;
		else
			combo++;
	}

	var curLight:Int = 0;
	var curLightEvent:Int = 0;
}
