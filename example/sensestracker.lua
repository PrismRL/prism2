
---@class SensesTracker : Object
---@field exploredCells SparseGrid
---@field otherSensedCells SparseGrid
---@field totalSensedActors SparseMap
---@field otherSensedActors SparseMap
local SensesTracker = prism.Object:extend("SensesTracker")

---@param level Level
---@param curActor Actor
function SensesTracker:createSensedMaps(level, curActor)
   self.exploredCells = prism.SparseGrid() 
   self.otherSensedActors = prism.SparseMap()
   self.otherSensedCells = prism.SparseGrid()
   self.totalSensedActors = prism.SparseMap()

   local actorSet = {}

   -- Collect explored cells
   for actor in level:eachActor(prism.components.PlayerController) do
      local sensesComponent = actor:getComponent(prism.components.Senses)
      for x, y, cell in sensesComponent.explored:each() do
         self.exploredCells:set(x, y, cell)
      end
   end

   for actor in level:eachActor(prism.components.PlayerController) do
      if actor ~= curActor then
         local sensesComponent = actor:getComponent(prism.components.Senses)
         for x, y, cell in sensesComponent.cells:each() do
            self.otherSensedCells:set(x, y, cell)
         end
      end
   end

   -- Collect other sensed actors
   for actor in level:eachActor(prism.components.PlayerController) do
      if actor ~= curActor then
         local sensesComponent = actor:getComponent(prism.components.Senses)
         for actorInSight in sensesComponent.actors:eachActor() do
            actorSet[actorInSight] = true
            self.otherSensedActors:insert(actorInSight.position.x, actorInSight.position.y, actorInSight)
         end
      end
   end

   local sensesComponent = curActor:getComponent(prism.components.Senses)
   if sensesComponent then
      for actor in sensesComponent.actors:eachActor() do
         actorSet[actor] = true
         self.totalSensedActors:insert(actor.position.x, actor.position.y, actor)
      end
   end

   for actor, _ in pairs(actorSet) do
      self.totalSensedActors:insert(actor.position.x, actor.position.y, actor)
   end
end

function SensesTracker:passableCallback()
   return function(x, y)
      local passable = false
      --- @type Cell
      local cell = self.exploredCells:get(x, y)

      if cell then 
         passable = cell.passable
      end

      for actor, _ in pairs(self.totalSensedActors:get(x, y)) do
         if actor:getComponent(prism.components.Collider) ~= nil then
            passable = false
         end
      end

      return passable
   end
end

return SensesTracker