-- Red-Eyes Thousand Dragon
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	Fusion.AddProcMix(c,true,true,s.mat1,s.mat2)
	-- Special Summon procedure (Contact Fusion)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetCondition(s.sprcon)
	e0:SetTarget(s.sprtg)
	e0:SetOperation(s.sprop)
	c:RegisterEffect(e0)
	-- All monsters become DARK
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CHANGE_ATTRIBUTE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e1:SetValue(ATTRIBUTE_DARK)
	c:RegisterEffect(e1)
	-- Cannot activate effects / attack
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_ACTIVATE)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(0,1)
	e2:SetValue(s.aclimit)
	c:RegisterEffect(e2)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_CANNOT_ATTACK)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(0,LOCATION_MZONE)
	e3:SetTarget(s.atlimit)
	c:RegisterEffect(e3)
	-- Leaves field
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
	e4:SetCode(EVENT_LEAVE_FIELD)
	e4:SetCondition(s.thcon)
	e4:SetTarget(s.thtg)
	e4:SetOperation(s.thop)
	c:RegisterEffect(e4)
end
s.material_setcode={0x3b}
function s.mat1(c,fc,sumtype,tp)
	return c:IsSetCard(0x3b,fc,sumtype,tp)
end
function s.mat2(c,fc,sumtype,tp)
	return c:IsSummonLocation(LOCATION_EXTRA)
end
function s.sprcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	local mg=Duel.GetMatchingGroup(function(mc) return mc:IsCanBeFusionMaterial(c) and mc:IsAbleToGraveAsCost() end,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
	for c1 in aux.Next(mg) do
		for c2 in aux.Next(mg) do
			if c1~=c2 and ((s.mat1(c1,c,SUMMON_TYPE_SPECIAL,tp) and s.mat2(c2,c,SUMMON_TYPE_SPECIAL,tp)) 
				or (s.mat1(c2,c,SUMMON_TYPE_SPECIAL,tp) and s.mat2(c1,c,SUMMON_TYPE_SPECIAL,tp))) then
				local g=Group.FromCards(c1,c2)
				if Duel.GetLocationCountFromEx(tp,tp,g,c)>0 then
					return true
				end
			end
		end
	end
	return false
end
function s.sprtg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local mg=Duel.GetMatchingGroup(function(mc) return mc:IsCanBeFusionMaterial(c) and mc:IsAbleToGraveAsCost() end,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local c1=mg:FilterSelect(tp,function(mc) 
		for c2 in aux.Next(mg) do
			if mc~=c2 and ((s.mat1(mc,c,SUMMON_TYPE_SPECIAL,tp) and s.mat2(c2,c,SUMMON_TYPE_SPECIAL,tp)) 
				or (s.mat1(c2,c,SUMMON_TYPE_SPECIAL,tp) and s.mat2(mc,c,SUMMON_TYPE_SPECIAL,tp))) then
				local g=Group.FromCards(mc,c2)
				if Duel.GetLocationCountFromEx(tp,tp,g,c)>0 then return true end
			end
		end
		return false
	end,1,1,nil):GetFirst()
	if c1 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
		local c2=mg:FilterSelect(tp,function(mc)
			if mc==c1 then return false end
			if not ((s.mat1(c1,c,SUMMON_TYPE_SPECIAL,tp) and s.mat2(mc,c,SUMMON_TYPE_SPECIAL,tp)) 
				or (s.mat1(mc,c,SUMMON_TYPE_SPECIAL,tp) and s.mat2(c1,c,SUMMON_TYPE_SPECIAL,tp))) then return false end
			local g=Group.FromCards(c1,mc)
			return Duel.GetLocationCountFromEx(tp,tp,g,c)>0
		end,1,1,nil):GetFirst()
		local g=Group.FromCards(c1,c2)
		g:KeepAlive()
		e:SetLabelObject(g)
		return true
	end
	return false
end
function s.sprop(e,tp,eg,ep,ev,re,r,rp,c)
	local sg=e:GetLabelObject()
	if not sg then return end
	Duel.SendtoGrave(sg,REASON_COST)
	c:SetMaterial(sg)
	sg:DeleteGroup()
end
function s.aclimit(e,re,tp)
	return re:GetHandler():IsAttribute(ATTRIBUTE_DARK) and re:GetHandler():IsLocation(LOCATION_MZONE)
end
function s.atlimit(e,c)
	return c:IsAttribute(ATTRIBUTE_DARK)
end
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousPosition(POS_FACEUP) and c:IsPreviousLocation(LOCATION_ONFIELD)
end
function s.spfilter3(c,e,tp)
	return c:IsSetCard(0x3b) and c:IsMonster() and not c:IsCode(id) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.setfilter(c)
	return c:IsSetCard(0x3b) and c:IsSpellTrap() and c:IsSSetable()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter3,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter3,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g>0 and Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)>0 then
		if Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_GRAVE,0,1,nil) and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
			local sg=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_GRAVE,0,1,1,nil)
			if #sg>0 then
				Duel.SSet(tp,sg)
			end
		end
	end
end
