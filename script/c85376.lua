--Masked HERO Tri-breaker
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--Fusion Material (for standard Fusion Summon, e.g. via Polymerization/Super Polymerization)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e0:SetCode(EFFECT_FUSION_MATERIAL)
	e0:SetValue(s.matfilter)
	c:RegisterEffect(e0)
	--Enforce "different Attributes" on whatever materials actually end up being used
	--(covers normal Fusion Summon via Polymerization etc.; the alt-summon below already
	--enforces this itself when selecting its own materials)
	local e0c=Effect.CreateEffect(c)
	e0c:SetType(EFFECT_TYPE_SINGLE)
	e0c:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0c:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0c:SetValue(s.spsumcon)
	c:RegisterEffect(e0c)
	--Alternative Special Summon: banish the above materials from GY and/or Extra Deck
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetCondition(s.spcon)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	local e1c=Effect.CreateEffect(c)
	e1c:SetType(EFFECT_TYPE_FIELD)
	e1c:SetCode(EFFECT_SPSUMMON_COST)
	e1c:SetRange(LOCATION_EXTRA)
	e1c:SetTargetRange(LOCATION_MZONE,0)
	e1c:SetCost(s.spcost)
	c:RegisterEffect(e1c)
	--(2) End Phase: if Special Summoned by the above method, banish 1 "HERO" from GY or send this card to GY
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EVENT_PHASE+PHASE_END)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.endcon)
	e2:SetOperation(s.endop)
	c:RegisterEffect(e2)
	--(3) Quick Effect: negate opponent's activation and destroy that card
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCondition(s.negcon)
	e3:SetTarget(s.negtg)
	e3:SetOperation(s.negop)
	c:RegisterEffect(e3)
	--(4) Once per turn: banish any number of "Masked HERO" from GY; gain 300 ATK each
	local e4=Effect.CreateEffect(c)
	e4:SetCategory(CATEGORY_ATKCHANGE)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,id)
	e4:SetCost(s.atkcost)
	e4:SetTarget(s.atktg)
	e4:SetOperation(s.atkop)
	c:RegisterEffect(e4)
end

--Shared filters
function s.matfilter(c)
	return c:IsSetCard(0xa008) and not c:IsCode(id)
end
function s.herofilter(c)
	return c:IsSetCard(0x8)
end
--checks the materials actually used for a genuine Fusion Summon (Polymerization etc.)
--if this card was summoned by our own alt-procedure below instead, no materials are
--registered through the Fusion system, so this simply passes
function s.spsumcon(e,c)
	if c==nil then return true end
	local mg=c:GetMaterial()
	if not mg or mg:GetCount()==0 then return true end
	return Auxiliary.GetAttributeCount(mg)>=3
end

--(1) Alternative Special Summon Procedure
function s.matgfilter(c)
	return c:IsSetCard(0xa008) and not c:IsCode(id) and c:IsAbleToRemoveAsCost()
end
function s.checkatt(g)
	if g:GetCount()<3 then return false end
	local atts={}
	local ct=0
	local tc=g:GetFirst()
	while tc do
		local att=tc:GetAttribute()
		if not atts[att] then
			atts[att]=true
			ct=ct+1
		end
		tc=g:GetNext()
	end
	return ct>=3
end
function s.spcon(e,c)
	if c==nil then
		local g=Duel.GetMatchingGroup(s.matgfilter,e:GetHandlerPlayer(),LOCATION_GRAVE+LOCATION_EXTRA,0,nil)
		return s.checkatt(g)
	else return true end
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local g=Duel.GetMatchingGroup(s.matgfilter,tp,LOCATION_GRAVE+LOCATION_EXTRA,0,nil)
		return s.checkatt(g)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g1=Duel.GetMatchingGroup(s.matgfilter,tp,LOCATION_GRAVE+LOCATION_EXTRA,0,nil)
	local tc1=g1:Select(tp,1,1,nil):GetFirst()
	Duel.Remove(tc1,POS_FACEUP,REASON_COST)
	local att1=tc1:GetAttribute()
	local g2=Duel.GetMatchingGroup(s.matgfilter,tp,LOCATION_GRAVE+LOCATION_EXTRA,0,nil)
	g2=g2:Filter(function(c) return c:GetAttribute()~=att1 end,nil)
	local tc2=g2:Select(tp,1,1,nil):GetFirst()
	Duel.Remove(tc2,POS_FACEUP,REASON_COST)
	local att2=tc2:GetAttribute()
	local g3=Duel.GetMatchingGroup(s.matgfilter,tp,LOCATION_GRAVE+LOCATION_EXTRA,0,nil)
	g3=g3:Filter(function(c) return c:GetAttribute()~=att1 and c:GetAttribute()~=att2 end,nil)
	local tc3=g3:Select(tp,1,1,nil):GetFirst()
	Duel.Remove(tc3,POS_FACEUP,REASON_COST)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1)
end

--(2) End Phase clause
function s.endcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:GetFlagEffect(id)>0
end
function s.endop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if Duel.IsExistingMatchingCard(s.herofilter,tp,LOCATION_GRAVE,0,1,nil)
		and Duel.SelectYesNo(tp,0) then
		local g=Duel.SelectMatchingCard(tp,s.herofilter,tp,LOCATION_GRAVE,0,1,1,nil)
		Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
	else
		Duel.SendtoGrave(c,REASON_EFFECT)
	end
end

--(3) Negate opponent's activation
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return re:IsActiveType(TYPE_MONSTER+TYPE_SPELL+TYPE_TRAP) and rp==1-tp
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsChainDisablable(ev) end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE+CATEGORY_DESTROY,re:GetHandler(),1,0,0)
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) then
		local rc=re:GetHandler()
		if re:IsHasType(EFFECT_TYPE_ACTIVATE) and rc:IsRelateToEffect(re) then
			Duel.Destroy(rc,REASON_EFFECT)
		end
	end
end

--(4) Banish "Masked HERO" from GY for ATK gain
function s.costfilter(c)
	return c:IsSetCard(0xa008) and c:IsAbleToRemoveAsCost()
end
function s.atkcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_GRAVE,0,1,nil) end
	local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_GRAVE,0,99,0,nil)
	local ct=g:GetCount()
	if ct>0 then
		Duel.Remove(g,POS_FACEUP,REASON_COST)
	end
	e:SetLabel(ct)
end
function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_ATKCHANGE,e:GetHandler(),1,0,0)
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local ct=e:GetLabel()
	if ct<=0 or not c:IsRelateToEffect(e) then return end
	local te=Effect.CreateEffect(c)
	te:SetType(EFFECT_TYPE_SINGLE)
	te:SetCode(EFFECT_UPDATE_ATTACK)
	te:SetValue(300*ct)
	te:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(te)
end
