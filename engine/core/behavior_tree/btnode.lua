--- The base class for all nodes in the behavior tree.
--- @class BTNode : Object, IBehavior
--- @overload fun(run: fun(self: BTNode, level: Level, actor: Actor, controller: ControllerComponent): boolean|Action): BTNode
--- @type BTNode
local BTNode = prism.Object:extend("BTNode")

--- You can also construct an anonymous node like:
--- prism.BTNode(function(level, actor) return true end)
--- For this reason simple nodes like succeeders, inverters, failers etc.
--- should just be created using these anonymous nodes.
--- @param run fun(self: BTNode, level: Level, actor: Actor, controller: ControllerComponent): boolean|Action
function BTNode:__new(run)
   self.run = run or self.run
end

--- Override this method in your own nodes, or supply an anonymous function
--- to the constructor to create an 'anonymous node'. While we pass in self here
--- it's generally not a good idea to store state on the nodes itself, but it can be
--- fine for caching a path for instance.
--- @param self BTNode
--- @param level Level
--- @param actor Actor
--- @param controller ControllerComponent
--- @return boolean|Action
function BTNode:run(level, actor, controller)
   error "BTNode is an abstract class! Extend it or provide a run method!"
end

return BTNode
