package;

import Section.SwagSection;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.tweens.FlxTween;
import flixel.util.FlxSort;
import haxe.Json;
import haxe.format.JsonParser;
import openfl.utils.Assets;
import flxanimate.FlxAnimate;

using StringTools;

typedef CharacterFile =
{
	var animations:Array<AnimArray>;
	var image:String;
	var scale:Float;
	var sing_duration:Float;
	var healthicon:String;

	var position:Array<Float>;
	var camera_position:Array<Float>;
	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;
}

typedef AnimArray =
{
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
}

class Character extends FlxSprite
{
	public var animOffsets:Map<String, Array<Dynamic>>;
	public var debugMode:Bool = false;

	public var isPlayer:Bool = false;
	public var curCharacter:String = DEFAULT_CHARACTER;

	public var colorTween:FlxTween;
	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var animationNotes:Array<Dynamic> = [];
	public var stunned:Bool = false;
	public var singDuration:Float = 4; // Multiplier of how long a character holds the sing pose
	public var idleSuffix:String = '';
	public var danceIdle:Bool = false; // Character use "danceLeft" and "danceRight" instead of "idle"
	public var skipDance:Bool = false;

	public var healthIcon:String = 'face';
	public var animationsArray:Array<AnimArray> = [];

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];

	public var hasMissAnimations:Bool = false;

	// Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var healthColorArray:Array<Int> = [255, 0, 0];

	public var alreadyLoaded:Bool = true; // Used by "Change Character" event

	public static var DEFAULT_CHARACTER:String = 'bf'; // In case a character is missing, it will use BF on its place

	public var zoomOffset:Float = 0;
	public var atlasCharacter:FlxAnimate;
	public var canAnimate:Bool = true;
	public var isCovering:Bool = false;
	public var hasTransformed:Bool = false;

	public function new(x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false)
	{
		super(x, y);

		#if (haxe >= "4.0.0")
		animOffsets = new Map();
		#else
		animOffsets = new Map<String, Array<Dynamic>>();
		#end
		curCharacter = character;
		this.isPlayer = isPlayer;
		antialiasing = SaveData.get(ANTIALIASING);

		switch (curCharacter)
		{
			case 'beelze':
				frames = Paths.getSparrowAtlas('characters/beelze_normal', "shared");
				animation.addByPrefix('idle', 'OldMan_Idle', 24, false);
				animation.addByPrefix('singUP', 'OldMan_Up', 24, false);
				animation.addByPrefix('singRIGHT', 'OldMan_Right', 24, false);
				animation.addByPrefix('singDOWN', 'OldMan_Down', 24, false);
				animation.addByPrefix('singLEFT', 'OldMan_Left', 24, false);
				animation.addByPrefix('Walk', 'OldMan_Walk', 24, false);
				animation.addByPrefix('Laugh', 'OldMan_Laugh', 24, false);

				addOffset("idle");
				addOffset("singUP", 59, 11);
				addOffset("singLEFT", 112, -6);
				addOffset("singRIGHT", -24, -6);
				addOffset("singDOWN", 51, -15);
				addOffset("Walk", 101, 20);
				addOffset("Laugh", 268, 35);

				playAnim('idle');

				setGraphicSize(Std.int(width * 0.725));

				for (i in animOffsets)
				{
					i[0] *= scale.x;
					i[1] *= scale.y;
				}

				healthColorArray = [126, 93, 145];
				cameraPosition = [-365, 80];
				healthIcon = "beelze";
				zoomOffset = 0.12;

			case 'beelzescary':
				frames = Paths.getSparrowAtlas('characters/beelze_ooscaryface', "shared");
				animation.addByPrefix('idle', 'OldMan_Creepy_Idle', 24, false);
				animation.addByPrefix('singUP', 'OldMan_Creepy_Up', 24, false);
				animation.addByPrefix('singRIGHT', 'OldMan_Creepy_Right', 24, false);
				animation.addByPrefix('singDOWN', 'OldMan_Creepy_Down', 24, false);
				animation.addByPrefix('singLEFT', 'OldMan_Creepy_Left', 24, false);

				addOffset("idle");
				addOffset("singUP", 71, 9);
				addOffset("singLEFT", 142, -8);
				addOffset("singRIGHT", -29, -6);
				addOffset("singDOWN", 65, -20);

				playAnim('idle');

				setGraphicSize(Std.int(width * 0.725));

				for (i in animOffsets)
				{
					i[0] *= scale.x;
					i[1] *= scale.y;
				}

				healthColorArray = [126, 93, 145];
				cameraPosition = [400, 80];
				healthIcon = "beelze"; // might check it
				zoomOffset = 0.18;
				antialiasing = true;

			// pending to add: hellbell and cntract

			case 'dawn' | 'dawn-bf':
				atlasCharacter = new FlxAnimate(x, y, Paths.getLibraryPath('images/characters/dawn', 'shared'));
				
				atlasCharacter.anim.addByAnimIndices('idle', indicesContinueAmount(24), 24);
				atlasCharacter.anim.addByAnimIndices('singLEFT', indicesContinueAmount(14), 24);
				atlasCharacter.anim.addByAnimIndices('singLEFTmiss', indicesContinueAmount(14), 24);
				atlasCharacter.anim.addByAnimIndices('singRIGHT', indicesContinueAmount(14), 24);
				atlasCharacter.anim.addByAnimIndices('singRIGHTmiss', indicesContinueAmount(14), 24);
				atlasCharacter.anim.addByAnimIndices('singUP', indicesContinueAmount(14), 24);
				atlasCharacter.anim.addByAnimIndices('singUPmiss', indicesContinueAmount(14), 24);
				atlasCharacter.anim.addByAnimIndices('singDOWN', indicesContinueAmount(14), 24);
				atlasCharacter.anim.addByAnimIndices('singDOWNmiss', indicesContinueAmount(14), 24);

				atlasCharacter.anim.addByAnimIndices('transition', indicesContinueAmount(11), 24);
				atlasCharacter.anim.addByAnimIndices('idle-cover', indicesContinueAmount(24), 24);
				atlasCharacter.anim.addByAnimIndices('singLEFT-cover', indicesContinueAmount(14), 24);
				atlasCharacter.anim.addByAnimIndices('singRIGHT-cover', indicesContinueAmount(14), 24);
				atlasCharacter.anim.addByAnimIndices('singUP-cover', indicesContinueAmount(14), 24);
				atlasCharacter.anim.addByAnimIndices('singDOWN-cover', indicesContinueAmount(14), 24);

				atlasCharacter.anim.addByAnimIndices('transform', indicesContinueAmount(24), 24);
				atlasCharacter.anim.addByAnimIndices('idle-transformed', indicesContinueAmount(24), 24);
				atlasCharacter.anim.addByAnimIndices('singLEFT-transformed', indicesContinueAmount(14), 24);
				atlasCharacter.anim.addByAnimIndices('singLEFTmiss-transformed', indicesContinueAmount(14), 24);
				atlasCharacter.anim.addByAnimIndices('singRIGHT-transformed', indicesContinueAmount(14), 24);
				atlasCharacter.anim.addByAnimIndices('singRIGHTmiss-transformed', indicesContinueAmount(14), 24);
				atlasCharacter.anim.addByAnimIndices('singUP-transformed', indicesContinueAmount(14), 24);
				atlasCharacter.anim.addByAnimIndices('singUPmiss-transformed', indicesContinueAmount(14), 24);
				atlasCharacter.anim.addByAnimIndices('singDOWN-transformed', indicesContinueAmount(14), 24);
				atlasCharacter.anim.addByAnimIndices('singDOWNmiss-transformed', indicesContinueAmount(14), 24);

				atlasCharacter.anim.addByAnimIndices('idle-boyfriend', indicesContinueAmount(24), 24);
				atlasCharacter.anim.addByAnimIndices('singLEFT-boyfriend', indicesContinueAmount(14), 24);
				atlasCharacter.anim.addByAnimIndices('singLEFTmiss-boyfriend', indicesContinueAmount(14), 24);
				atlasCharacter.anim.addByAnimIndices('singRIGHT-boyfriend', indicesContinueAmount(14), 24);
				atlasCharacter.anim.addByAnimIndices('singRIGHTmiss-boyfriend', indicesContinueAmount(14), 24);
				atlasCharacter.anim.addByAnimIndices('singUP-boyfriend', indicesContinueAmount(14), 24);
				atlasCharacter.anim.addByAnimIndices('singUPmiss-boyfriend', indicesContinueAmount(14), 24);
				atlasCharacter.anim.addByAnimIndices('singDOWN-boyfriend', indicesContinueAmount(14), 24);
				atlasCharacter.anim.addByAnimIndices('singDOWNmiss-boyfriend', indicesContinueAmount(14), 24);

				atlasCharacter.anim.addByAnimIndices('transition-boyfriend', indicesContinueAmount(14), 24);
				atlasCharacter.anim.addByAnimIndices('idle-cover-boyfriend', indicesContinueAmount(24), 24);
				atlasCharacter.anim.addByAnimIndices('singLEFT-cover-boyfriend', indicesContinueAmount(14), 24);
				atlasCharacter.anim.addByAnimIndices('singRIGHT-cover-boyfriend', indicesContinueAmount(14), 24);
				atlasCharacter.anim.addByAnimIndices('singUP-cover-boyfriend', indicesContinueAmount(14), 24);
				atlasCharacter.anim.addByAnimIndices('singDOWN-cover-boyfriend', indicesContinueAmount(14), 24);

				atlasCharacter.scale.set(1.25, 1.25);
				atlasCharacter.antialiasing = true;

				PlayState.instance.add(atlasCharacter);

				healthColorArray = [200, 200, 200];
				zoomOffset = -0.08;
				healthIcon = "dawn";

				setGraphicSize(Std.int(width * 1.2));
				atlasCharacter.setPosition(x, y);
			// case 'your character name in case you want to hardcode him instead':
			default:
				var characterPath:String = 'characters/' + curCharacter + '.json';
				var path:String = Paths.getPreloadPath(characterPath);
				if (!Assets.exists(path))
				{
					path = Paths.getPreloadPath('characters/' + DEFAULT_CHARACTER +
						'.json'); // If a character couldn't be found, change him to BF just to prevent a crash
				}

				var rawJson = Assets.getText(path);
				var spriteType = "sparrow";

				var json:CharacterFile = cast Json.parse(rawJson);
				if (Assets.exists(Paths.getPath('images/' + json.image + '.txt', TEXT)))
					spriteType = "packer";

				if (Assets.exists(Paths.getPath('images/' + json.image + '/Animation.json', TEXT)))
					spriteType = "texture";

				#if STORAGE_ACCESS
				if (SaveData.get(ALLOW_FILESYS))
				{
					var extChar = features.StorageAccess.getCharacter(curCharacter);
					if (extChar != null)
					{
						json = extChar[0];
						frames = extChar[1];
					}
					else
						setupFromAssets(spriteType, json);
				}
				else
					setupFromAssets(spriteType, json);
				#else
				setupFromAssets(spriteType, json);
				#end

				imageFile = json.image;

				if (json.scale != 1)
				{
					jsonScale = json.scale;
					setGraphicSize(Std.int(width * jsonScale));
					updateHitbox();
				}

				positionArray = json.position;
				cameraPosition = json.camera_position;

				healthIcon = json.healthicon;
				singDuration = json.sing_duration;
				flipX = !!json.flip_x;
				if (json.no_antialiasing)
					noAntialiasing = true;

				if (json.healthbar_colors != null && json.healthbar_colors.length > 2)
					healthColorArray = json.healthbar_colors;

				antialiasing = !noAntialiasing;
				if (!SaveData.get(ANTIALIASING))
					antialiasing = false;

				animationsArray = json.animations;
				if (animationsArray != null && animationsArray.length > 0)
				{
					for (anim in animationsArray)
					{
						var animAnim:String = '' + anim.anim;
						var animName:String = '' + anim.name;
						var animFps:Int = anim.fps;
						var animLoop:Bool = !!anim.loop; // Bruh
						var animIndices:Array<Int> = anim.indices;
						if (animIndices != null && animIndices.length > 0)
						{
							animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
						}
						else
						{
							animation.addByPrefix(animAnim, animName, animFps, animLoop);
						}

						if (anim.offsets != null && anim.offsets.length > 1)
						{
							addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
						}
					}
				}
				else
				{
					quickAnimAdd('idle', 'BF idle dance');
				}
		}
		originalFlipX = flipX;

		if (animOffsets.exists('singLEFTmiss') || animOffsets.exists('singDOWNmiss') || animOffsets.exists('singUPmiss') || animOffsets.exists('singRIGHTmiss'))
			hasMissAnimations = true;
		recalculateDanceIdle();
		dance();

		if (isPlayer)
		{
			flipX = !flipX;
		}
	}

	public var atlasAnimation:String = ''; 
	public var isPressing:Bool = false;
	public var uncoverCooldown:Float;

	override function update(elapsed:Float)
	{
		if (!debugMode)
		{
			if (atlasCharacter == null && animation.curAnim != null)
			{
				if (heyTimer > 0)
				{
					heyTimer -= elapsed;
					if (heyTimer <= 0)
					{
						if (specialAnim && animation.curAnim.name == 'hey' || animation.curAnim.name == 'cheer')
						{
							specialAnim = false;
							dance();
						}
						heyTimer = 0;
					}
				}
				else if (specialAnim && animation.curAnim.finished)
				{
					specialAnim = false;
					dance();
				}

				if (!isPlayer)
				{
					if (animation.curAnim.name.startsWith('sing'))
						holdTimer += elapsed;

					if (holdTimer >= Conductor.stepCrochet * 0.0011 * singDuration)
					{
						dance();
						holdTimer = 0;
					}
				}

				if (animation.curAnim.finished && animation.getByName(animation.curAnim.name + '-loop') != null)
				{
					playAnim(animation.curAnim.name + '-loop');
				}
			}
			else
			{
				if (atlasAnimation.startsWith("sing"))
					holdTimer += elapsed;

				if (holdTimer >= Conductor.stepCrochet * 0.0011 * singDuration)
				{
					dance();
					holdTimer = 0;
				}

				if (isPressing)
				{
					coverEars(true);
					uncoverCooldown = (8 * (Conductor.stepCrochet / 1000));
				}
				else
				{
					uncoverCooldown -= elapsed;
					if (uncoverCooldown <= 0)
						coverEars(false);
				}
			}
		}
		super.update(elapsed);
	}

	public var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance(?forced:Bool = false)
	{
		if (!debugMode && !skipDance && !specialAnim)
		{
			if (atlasCharacter != null)
				playAnim('idle', forced);
			else 
				if (danceIdle)
				{
					danced = !danced;

					if (danced)
						playAnim('danceRight' + idleSuffix);
					else
						playAnim('danceLeft' + idleSuffix);
				}
				else if (animation.getByName('idle' + idleSuffix) != null)
				{
					playAnim('idle' + idleSuffix);
				}
		}
	}

	public function coverEars(?yaCover:Bool = false)
	{
		if (isCovering != yaCover && !hasTransformed)
		{
			canAnimate = false;
			var modifier = '';
			if (curCharacter == 'dawn-bf')
				modifier += '-boyfriend';
			atlasCharacter.anim.play('transition' + modifier, true, !yaCover, (yaCover ? 0 : 4));
			atlasAnimation = 'transition' + modifier;
			isCovering = yaCover;
			atlasCharacter.anim.onComplete = function()
			{
				if (atlasAnimation.contains('transition') && !canAnimate)
				{
					canAnimate = true;
					dance();
				}
			};
		}
	}

	public function transformDawn()
	{
		if (!hasTransformed)
		{
			canAnimate = false;
			atlasCharacter.anim.play('transform');
			atlasAnimation = 'transform';
			hasTransformed = true;
			atlasCharacter.anim.onComplete = function()
			{
				if (atlasAnimation.contains('transform') && !canAnimate)
				{
					canAnimate = true;
					dance();
				}
			};
		}
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		if (!canAnimate
			|| (atlasAnimation.contains('transition')
				&& ((!atlasCharacter.anim.reversed && atlasCharacter.anim.curFrame < 3)
					|| (atlasCharacter.anim.reversed && atlasCharacter.anim.curFrame > 2))))
		{
			return;
		}
		else
			canAnimate = true;

		var modifier = '';
		if (isCovering && !hasTransformed)
			modifier += '-cover';
		if (hasTransformed)
			modifier += '-transformed';
		if (curCharacter == 'dawn-bf')
			modifier += '-boyfriend';

		specialAnim = false;
		if (atlasCharacter != null)
		{
			atlasCharacter.anim.play(AnimName + modifier, Force, Reversed, Frame);
			atlasAnimation = AnimName;
		}
		else
		{
			animation.play(AnimName, Force, Reversed, Frame);
	
			var daOffset = animOffsets.get(AnimName);
			if (animOffsets.exists(AnimName))
			{
				offset.set(daOffset[0], daOffset[1]);
			}
			else
				offset.set(0, 0);
	
			if (curCharacter.startsWith('gf'))
			{
				if (AnimName == 'singLEFT')
				{
					danced = true;
				}
				else if (AnimName == 'singRIGHT')
				{
					danced = false;
				}
	
				if (AnimName == 'singUP' || AnimName == 'singDOWN')
				{
					danced = !danced;
				}
			}
		}
	}

	function sortAnims(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	public var danceEveryNumBeats:Int = 2;

	private var settingCharacterUp:Bool = true;

	public function recalculateDanceIdle()
	{
		var lastDanceIdle:Bool = danceIdle;
		danceIdle = (animation.getByName('danceLeft' + idleSuffix) != null && animation.getByName('danceRight' + idleSuffix) != null);

		if (settingCharacterUp)
		{
			danceEveryNumBeats = (danceIdle ? 1 : 2);
		}
		else if (lastDanceIdle != danceIdle)
		{
			var calc:Float = danceEveryNumBeats;
			if (danceIdle)
				calc /= 2;
			else
				calc *= 2;

			danceEveryNumBeats = Math.round(Math.max(calc, 1));
		}
		settingCharacterUp = false;
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

	public function quickAnimAdd(name:String, anim:String)
	{
		animation.addByPrefix(name, anim, 24, false);
	}

	private function setupFromAssets(spriteType:String, json:CharacterFile)
	{
		switch (spriteType)
		{
			case "packer":
				frames = Paths.getPackerAtlas(json.image);
			case "sparrow":
				frames = Paths.getSparrowAtlas(json.image);
		}
	}

	public static function generateIndicesAtPoint(point:Int, amount:Int):Array<Int>
	{
		var returnArray:Array<Int> = [];
		for (i in 0...amount)
			returnArray.push((point - 1) + i);
		return returnArray;
	}

	public var currentIndex:Int = 1;

	public function indicesContinueAmount(amount:Int):Array<Int>
	{
		var theArray:Array<Int> = generateIndicesAtPoint(currentIndex, amount);
		currentIndex += amount;
		return theArray;
	}
}
