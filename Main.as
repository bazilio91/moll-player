package  
{
	import fl.video.FLVPlayback;
	import fl.video.VideoEvent;
	import com.soulwire.geom.ColourMatrix;
	import com.soulwire.media.MotionTracker;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.ColorMatrixFilter;
	import flash.media.Camera;
	import flash.media.Video;
	import flash.utils.*;
	import flash.net.navigateToURL;
	import flash.net.URLRequest;
	import flash.net.URLLoader;
	import flash.events.StatusEvent;
	import flash.system.*
	import fl.video.VideoPlayer;
	
	public class Main extends Sprite
	{
		
		/*
		========================================================
		| Private Variables                         | Data Type  
		========================================================
		*/
		
		private var _motionTracker:					MotionTracker;
		
		private var _target:						Shape;
		private var _bounds:						Shape;
		private var _output:						Bitmap;
		private var _source:						Bitmap;
		private var _video:							BitmapData;
		private var _matrix:						ColourMatrix;
		private var _hitzoneLeft: 					Hitzone;
		private var _hitzoneRight: 					Hitzone;
		private var _stopHitTest: 					Boolean;
		private var _timeOut:						Number;
		private var cam: 							Camera;
		
		private var video_x:Number;
		private var video_y:Number;

		private var video_h:Number;
		private var video_w:Number;
		
		private var video_bg;
		
		private var my_videos:XMLList;
		private var my_total:Number;
		private var my_current:						Number;
		private var my_status:						Boolean;
		
		private var my_player:FLVPlayback;
		private var main_container:Sprite;
		
		private var myXMLLoader:URLLoader;
		private var mc:MovieClip;
		/*
		========================================================
		| Constructor
		========================================================
		*/
		
		public function Main() 
		{
			/*** SETUP ***/
			stage.align = "TL";
			//stage.displayState="fullScreen";
			myXMLLoader = new URLLoader();
			myXMLLoader.load(new URLRequest("params.xml"));
			myXMLLoader.addEventListener(Event.COMPLETE, processXML);
			
			mc = new MovieClip();

			var camW:int = 300;
			var camH:int = 250;
			_stopHitTest = true;
			
			// Create the camera
			//cam = Camera.getCamera();
			
			if (Capabilities.os.indexOf("Mac")>-1){
				cam = Camera.getCamera("2");
			}else{
				cam = Camera.getCamera()
			}
			
			cam.setMode( camW, camH, stage.frameRate );
			cam.addEventListener(StatusEvent.STATUS, statusHandler);
			
			// Create a video
			var vid:Video = new Video( camW, camH );
			vid.attachCamera( cam );
			
			// Create the Motion Tracker
			_motionTracker = new MotionTracker( vid );
			
			// We flip the input as we want a mirror image
			_motionTracker.flipInput = true;
			
			
			/*** Create a few things to help us visualise what the MotionTracker is doing... ***/
			
			
			_matrix = new ColourMatrix();
			_matrix.brightness = _motionTracker.brightness;
			_matrix.contrast = _motionTracker.contrast;
			
			// Display the camera input with the same filters (minus the blur) as the MotionTracker is using
			_video = new BitmapData( camW, camH, false, 0 );
			_source = new Bitmap( _video );
			_source.scaleX = -1;
			_source.x = camW;
			_source.filters = [ new ColorMatrixFilter( _matrix.getMatrix() ) ];
			addChild( _source );
			
			// Show the image the MotionTracker is processing and using to track
			_output = new Bitmap( _motionTracker.trackingImage );
			_output.x = camW;
			addChild( _output );
			
			
			// A shape to represent the tracking point
			_target = new Shape();
			_target.graphics.lineStyle( 0, 0xFFFFFF );
			_target.graphics.drawCircle( 0, 0, 10 );
			addChild( _target );
			
			// A box to represent the activity area
			_bounds = new Shape();
			_bounds.x = _output.x;
			_bounds.y = _output.y;
			addChild( _bounds );
			
		    _hitzoneLeft = new Hitzone();
			_hitzoneLeft.x = camW;
		    addChild(_hitzoneLeft);
		    
		    _hitzoneRight = new Hitzone();
			_hitzoneRight.x = camW*2-_hitzoneRight.width;
		    addChild(_hitzoneRight);

			
			// Configure the UI
			blurStep.addEventListener( Event.CHANGE, setValues );
			brightnessStep.addEventListener( Event.CHANGE, setValues );
			contrastStep.addEventListener( Event.CHANGE, setValues );
			areaStep.addEventListener( Event.CHANGE, setValues );
			
			okButton.addEventListener( MouseEvent.CLICK, hideControls );
			
			// Get going!
			addEventListener( Event.ENTER_FRAME, track );
			stage.addEventListener(Event.RESIZE, resizeHandler);
		}
		
		private function resizeHandler(event:Event):void {
			trace("stageWidth: "+stage.stageWidth);
			trace("stageHeight: "+stage.stageHeight);
			mc.width = stage.stageWidth;
			mc.height = stage.stageHeight;
			my_player.width = stage.stageWidth;
			my_player.height = stage.stageHeight;
		}
		
		private function processXML (e:Event):void{
			trace('processXML');
			var myXML:XML = new XML(e.target.data);
		
			video_x = myXML.@VIDEO_X;
			video_y = myXML.@VIDEO_Y;
			
			video_h = myXML.@VIDEO_H;
			video_w = myXML.@VIDEO_W;
			
			video_bg = myXML.@BG;
			
			my_videos = myXML.VIDEO;
			my_total = my_videos.length();
			
			mc.graphics.beginFill(video_bg);
			mc.graphics.drawRect(0, 0, 720, 480);//stage.stageWidth, stage.stageHeight);
			mc.graphics.endFill();
			mc.x = 0;
			mc.y = 0;
			addChild(mc);
			setChildIndex(mc, 0);
			
			makeContainers();
			makePlayer();
		}
		
		private function makeContainers():void{
			main_container = new Sprite();
			addChild(main_container);
			setChildIndex(main_container, 1);
		}
		
		private function makePlayer():void{
			trace('makePlayer');
			my_player = new FLVPlayback();
			var vidPlayer:VideoPlayer = my_player.getVideoPlayer(0);
			vidPlayer.smoothing = true;
			//my_player.skin = "SkinOverPlaySeekMute.swf";
			my_player.skinBackgroundColor = video_bg;
			my_player.skinBackgroundAlpha = 1;
			
			
			//my_player.width = video_w;
			//my_player.height = video_h;
			my_player.width = 720;//stage.stageWidth;
			my_player.height = 480;//stage.stageHeight;
			
			
			//trace(stage.stageWidth);
			//stage.stageWidth = video_w;
			//this.height = video_h;
			my_player.addEventListener(Event.COMPLETE, completePlay);
			function completePlay(e:Event):void {
				my_player.stop();
				my_player.source = my_videos[0].@URL;
				my_player.play();
				trace('completePlay');
				my_status = true;
			}
			
			main_container.addChild(my_player);
			my_player.x = 0;
			my_player.y = 0;
			var video_url = my_videos[0].@URL;
			my_current = 1;
			my_status = true;
			my_player.source = video_url;
		}
		
		/*
		========================================================
		| Event Handlers
		========================================================
		*/
		
		private function statusHandler(event:StatusEvent)
		{ 	
    		if(event.code=="Camera.Unmuted")
    		{
				cam.removeEventListener(StatusEvent.STATUS, statusHandler);
    			//var url:URLRequest = new URLRequest("javascript:camActivated('true')");
				//navigateToURL(url, "_self");
    		};
		};
		
		private function hideControls( e:MouseEvent ):void  {
			blurStep.visible = false;
			brightnessStep.visible = false;
			contrastStep.visible = false;
			areaStep.visible = false;
			
			blurLabel.visible = false;
			brightnessLabel.visible = false;
			contrastLabel.visible = false;
			areaLabel.visible = false;
			
			okButton.visible = false;
			
			_source.visible = false;
			_output.visible = false;
			_target.visible = false;
			_bounds.visible = false;
		    _hitzoneLeft.visible = false;
		    _hitzoneRight.visible = false;
		}
		
		
		private function track( e:Event ):void
		{
			// Tell the MotionTracker to update itself
			_motionTracker.track();
			
			// Move the target with some easing
			_target.x += ((_motionTracker.x + _bounds.x) - _target.x);
			_target.y += ((_motionTracker.y + _bounds.y) - _target.y);
			
			_video.draw( _motionTracker.input );
			
			// If there is enough movement (see the MotionTracker's minArea property) then continue
			if ( !_motionTracker.hasMovement ) return;
			
			// Draw the motion bounds so we can see what the MotionTracker is doing
			_bounds.graphics.clear();
			_bounds.graphics.lineStyle( 0, 0xFFFFFF );
			_bounds.graphics.drawRect( _motionTracker.motionArea.x,
									   _motionTracker.motionArea.y,
									   _motionTracker.motionArea.width,
									   _motionTracker.motionArea.height
										);
										
			if (_target.hitTestObject(_hitzoneLeft))
			{
				if(_stopHitTest == true)
				{
					trace("hittest:left");
					if(my_status == true) {
						my_status = false;
						if(my_current >= my_total) my_current = 1;
						trace('playing: ' + my_current.toString());
						my_player.source = my_videos[my_current++].@URL;
						//var url:URLRequest = new URLRequest("javascript:getFlashWebcam('left')");
				 		//navigateToURL(url, "_self");
					}
				};
				_stopHitTest = false;
				clearInterval(_timeOut);
				 _timeOut = setTimeout(stopHitTest, 1500);
				
			};
			
			if (_target.hitTestObject(_hitzoneRight)) 
			{
				if(_stopHitTest == true)
				{
					trace("hittest:right");
					if(my_status == true) {
						my_status = false;
						if(my_current >= my_total) my_current = 1; 
						trace('playing: ' + my_current.toString());
						my_player.source = my_videos[my_current++].@URL;
						
					}
					//var url2:URLRequest = new URLRequest("javascript:getFlashWebcam('right')");
					//navigateToURL(url2, "_self");
				};
				_stopHitTest = false;
				clearInterval(_timeOut);
				 _timeOut = setTimeout(stopHitTest, 1500);
				 
			};
			
		};
		
		function stopHitTest(){_stopHitTest = true};

		private function setValues( e:Event ):void
		{
			switch( e.currentTarget )
			{
				case blurStep :
					_motionTracker.blur = blurStep.value;
				break;
				
				case brightnessStep :
					_motionTracker.brightness = _matrix.brightness = brightnessStep.value;
				break;
				
				case contrastStep :
					_motionTracker.contrast = _matrix.contrast = contrastStep.value;
				break;
				
				case areaStep :
					_motionTracker.minArea = areaStep.value;
				break;
			}
			
			_source.filters = [ new ColorMatrixFilter( _matrix.getMatrix() ) ];
		}
		
	}
	
}
