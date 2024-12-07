--- The 'ActorStorage' is a container for 'Actors' that maintains a list, spatial map, and component cache.
--- It is used by the 'Level' class to store and retrieve actors, and is returned by a few Level methods.
--- You should rarely, if ever, need to instance this class yourself, it's mostly used internally and for
--- a few returns from Level.
--- @class ActorStorage : Object
--- @field actors table The list of actors in the storage.
--- @field sparseMap SparseMap The spatial map for storing actor positions.
--- @field componentCache table The cache for storing actor components.
--- @field insertSparseMapCallback function
--- @field removeSparseMapCallback function
--- @overload fun(): ActorStorage
--- @type ActorStorage
local ActorStorage = prism.Object:extend("ActorStorage")

--- The constructor for the 'ActorStorage' class.
--- Initializes the list, spatial map, and component cache.
function ActorStorage:__new(root, insertSparseMapCallback, removeSparseMapCallback)
   self.root = self.root or false
   self.actors = {}
   self.actorsSet = {}
   self.sparseMap = prism.SparseMap()
   self.componentCache = {}
   self.insertSparseMapCallback = insertSparseMapCallback or function() end
   self.removeSparseMapCallback = removeSparseMapCallback or function() end
end

--- Adds an actor to the storage, updating the spatial map and component cache.
--- @param actor Actor The actor to add.
function ActorStorage:addActor(actor)
   assert(actor:is(prism.Actor), "Tried to add a non-actor object to actor storage!")
   if self.actorsSet[actor] then return end

   table.insert(self.actors, actor)
   self:updateComponentCache(actor)
   self:insertSparseMapEntries(actor)
   self.actorsSet[actor] = true
end

--- Removes an actor from the storage, updating the spatial map and component cache.
--- @param actor Actor The actor to remove.
function ActorStorage:removeActor(actor)
   assert(actor:is(prism.Actor), "Tried to remove a non-actor object from actor storage!")
   if not self.actorsSet[actor] then return end

   self:removeComponentCache(actor)
   self:removeSparseMapEntries(actor)

   for k, v in ipairs(self.actors) do
      if v == actor then return table.remove(self.actors, k) end
   end
   
   self.actorsSet[actor] = nil
end

--- Returns whether the storage contains the specified actor.
--- @param actor Actor The actor to check.
--- @return boolean True if the storage contains the actor, false otherwise.
function ActorStorage:hasActor(actor)
   return self.actorsSet[actor]
end

--- Returns an iterator over the actors in the storage. If a component is specified, only actors with that 
--- component will be returned.
--- @param ... Component? The components to filter by.
--- @return function iter An iterator over the actors in the storage.
function ActorStorage:eachActor(...)
   local n = 1
   local comp = { ... }

   if #comp == 1 and self.componentCache[comp[1]] then
      local currentComponentCache = self.componentCache[comp[1]]
      local key = next(currentComponentCache, nil)

      return function()
         if not key then return end

         local ractor, rcomp = key, key:getComponent(comp[1])
         key = next(currentComponentCache, key)

         return ractor, rcomp
      end
   end

   return function()
      for i = n, #self.actors do
         n = i + 1

         if #comp == 0 then return self.actors[i] end

         local components = {}
         local hasComponents = false
         for j = 1, #comp do
            if self.actors[i]:hasComponent(comp[j]) then
               hasComponents = true
               table.insert(components, self.actors[i]:getComponent(comp[j]))
            else
               hasComponents = false
               break
            end
         end

         if hasComponents then return self.actors[i], unpack(components) end
      end

      return nil
   end
end

--- Returns an iterator over the actors in the storage that have the specified prototype.
--- @param prototype Actor The prototype to filter by.
--- @return Actor|nil The first actor that matches the prototype, or nil if no actor matches.
function ActorStorage:getActorByType(prototype)
   for i = 1, #self.actors do
      if self.actors[i]:is(prototype) then return self.actors[i] end
   end
end

--- Returns a table of actors in the storage at the given position.
--- TODO: Return an ActorStorage object instead of a table.
--- @param x number The x-coordinate to check.
--- @param y number The y-coordinate to check.
--- @return table<Actor> actors A table of actors at the given position.
function ActorStorage:getActorsAt(x, y)
   local actorsAtPosition = {}
   for actor, _ in pairs(self.sparseMap:get(x, y)) do
      table.insert(actorsAtPosition, actor)
   end

   return actorsAtPosition
end

--- Returns an iterator over the actors in the storage at the given position.
--- @param x number The x-coordinate to check.
--- @param y number The y-coordinate to check.
--- @return function iterator An iterator over the actors at the given position.
function ActorStorage:eachActorAt(x, y)
   local key, _
   local actors = self.sparseMap:get(x, y)
   local function iterator()
      key, _ = next(actors, key)
      return key
   end
   return iterator
end

--- Removes the specified actor from the spatial map.
--- @param actor Actor The actor to remove.
function ActorStorage:removeSparseMapEntries(actor)
   local pos = actor:getPosition()
   self.sparseMap:remove(pos.x, pos.y, actor)
   self.removeSparseMapCallback(pos.x, pos.y, actor)
end
 
--- Inserts the specified actor into the spatial map.
--- @param actor Actor The actor to insert.
function ActorStorage:insertSparseMapEntries(actor)
   local pos = actor:getPosition()
   self.sparseMap:insert(pos.x, pos.y, actor)
   self.insertSparseMapCallback(pos.x, pos.y, actor)
end

--- Updates the component cache for the specified actor.
--- @param actor Actor The actor to update the component cache for.
function ActorStorage:updateComponentCache(actor)
   for _, component in pairs(prism.components) do
      if not self.componentCache[component] then self.componentCache[component] = {} end

      if actor:hasComponent(component) then
         self.componentCache[component][actor] = true
      else
         self.componentCache[component][actor] = nil
      end
   end
end

--- Removes the specified actor from the component cache.
--- @param actor Actor The actor to remove from the component cache.
function ActorStorage:removeComponentCache(actor)
   for _, component in pairs(prism.components) do
      if self.componentCache[component] then self.componentCache[component][actor] = nil end
   end
end

--- Merges another ActorStorage instance with this one.
--- @param other ActorStorage The other ActorStorage instance to merge with this one.
function ActorStorage:merge(other)
   assert(other:is(ActorStorage), "Tried to merge a non-ActorStorage object with actor storage!")

   for _, actor in ipairs(other.actors) do
      self:addActor(actor)
   end
end

return ActorStorage
