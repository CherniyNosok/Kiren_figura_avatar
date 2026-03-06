local squapi = require("scripts/libs/SquAPI")
local tailPhysics = require("scripts/libs/tail")

vanilla_model.PLAYER:setVisible(false)


local ears = models.models.ears
local head = models.models.model.root.torso.Head
local tail = {
  models.models.tail.Tail.Tail1,
  models.models.tail.Tail.Tail1.Tail2,
  models.models.tail.Tail.Tail1.Tail2.Tail3,
  models.models.tail.Tail.Tail1.Tail2.Tail3.Tail4,
  models.models.tail.Tail.Tail1.Tail2.Tail3.Tail4.Tail5,
  models.models.tail.Tail.Tail1.Tail2.Tail3.Tail4.Tail5.Tail6,
  models.models.tail.Tail.Tail1.Tail2.Tail3.Tail4.Tail5.Tail6.Tail7,
  models.models.tail.Tail.Tail1.Tail2.Tail3.Tail4.Tail5.Tail6.Tail7.Tail8,
  models.models.tail.Tail.Tail1.Tail2.Tail3.Tail4.Tail5.Tail6.Tail7.Tail8.Tail9,
  models.models.tail.Tail.Tail1.Tail2.Tail3.Tail4.Tail5.Tail6.Tail7.Tail8.Tail9.Tail10
}

squapi.eye:new(
  models.models.model.root.torso.Head.Eyes.PupilLeft,
  1.2, 0.25, 0.5, 0.5
)
squapi.eye:new(
  models.models.model.root.torso.Head.Eyes.PupilRight,
  0.25, 1.2, 0.5, 0.5
)

squapi.smoothHead:new(
    {
      models.models.model.root.torso,
    	models.models.model.root.torso.Head --element(you can have multiple elements in a table)
    },
	{
		0.15,
		1
	},    --(1) strength(you can make this a table too)
    0.1,    --(0.1) tilt
    1,    --(1) speed
    nil,    --(true) keepOriginalHeadPos
    false,     --(true) fixPortrait
    nil,     --(nil) animStraightenList
    nil,     --(0.5) straightenMultiplier
    nil,     --(0.5) straightenSpeed
    nil     --(0.1) blendToConsiderStopped
)

squapi.ear:new(
  ears.Ears.EarLeft,
  ears.Ears.EarRight,
  0.75, --(1) rangeMultiplier
  false, --(false) horizontalEars
  1, --(2) bendStrength
  nil, --(true) doEarFlick
  nil, --(400) earFlickChance
  nil, --(0.1) earStiffness
  0.5  --(0.8) earBounce
)

squapi.randimation:new(
  animations["models.model"].blink,
  nil,    --(100) minTime
  nil,    --(300) maxTime
  nil     --(false) stopOnSleep
)

local tailModel = tailPhysics.new(models.models.tail.Tail.Tail1)
tailModel:setConfig {
  idleSpeed = vec(0.01, 0.1, 0.01),
  idleStrength = vec(2, 8, 0.1),
  walkSpeed = vec(0, 0.75, 0),
  walkStrength = vec(0.2, 1, 0.05),
  bounce = 0.1,
  stiff = 0.1,
}

--entity init event, used for when the avatar entity is loaded for the first time
function events.entity_init()
  ears:moveTo(head)
  models.models.tail:moveTo(models.models.model.root.torso.Body)
end

--tick event, called 20 times per second
function events.tick()
  --code goes here
end

--render event, called every time your avatar is rendered
--it have two arguments, "delta" and "context"
--"delta" is the percentage between the last and the next tick (as a decimal value, 0.0 to 1.0)
--"context" is a string that tells from where this render event was called (the paperdoll, gui, player render, first person)
function events.render(delta, context)
  --code goes here
end
