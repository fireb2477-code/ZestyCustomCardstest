-- Storm of Black Feathers
local s,id=GetID()
function s.initial_effect(c)
	--Activate from hand
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_TRAP_ACT_IN_HAND)
	e1:SetCondition(s.handcon)
	c:RegisterEffect(e1)
	--Activate
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_DISABLE+CATEGORY_DAMAGE)
	e2:SetType(EFFECT_TYPE_ACTIVATE)
	e2:SetCode(EVENT_CHAINING)
	e2:SetCondition(s.condition)
	e2:SetCost(s.cost)
	e2:SetTarget(s.target)
	e2:SetOperation(s.activate)
	c:RegisterEffect(e2)
end
function s.handcon(e)
	return Duel.GetCounter(0,1,1,0x10)>=5
end
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp and Duel.GetCurrentChain()>=1
end
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	local ct=ev+1
	if chk==0 then return Duel.IsCanRemoveCounter(tp,1,1,0x10,ct,REASON_COST) end
	Duel.RemoveCounter(tp,1,1,0x10,ct,REASON_COST)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local ct=0
	for i=1,ev do
		local p=Duel.GetChainInfo(i,CHAININFO_TRIGGERING_PLAYER)
		if p==1-tp then ct=ct+1 end
	end
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,nil,ct,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,ct*700)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local ct=0
	for i=1,ev do
		local p=Duel.GetChainInfo(i,CHAININFO_TRIGGERING_PLAYER)
		if p==1-tp then
			if Duel.NegateEffect(i) then
				ct=ct+1
			end
		end
	end
	if ct>0 then
		Duel.Damage(1-tp,ct*700,REASON_EFFECT)
	end
end
