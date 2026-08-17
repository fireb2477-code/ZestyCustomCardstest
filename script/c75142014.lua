-- Blue Swordsman of The Red-Eyes
local s,id=GetID()
function s.initial_effect(c)
	-- Link Summon
	Link.AddProcedure(c,nil,2,2,s.lcheck)
	c:EnableReviveLimit()
	-- Also FIRE
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_ADD_ATTRIBUTE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(ATTRIBUTE_FIRE)
	c:RegisterEffect(e1)
	-- ATK up
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)
	-- Cannot be sent to GY
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetCode(EFFECT_CANNOT_TO_GRAVE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCondition(s.tgcon)
	e3:SetValue(s.tgval)
	c:RegisterEffect(e3)
	-- Quick Effect
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,id)
	e4:SetTarget(s.efftg)
	e4:SetOperation(s.effop)
	c:RegisterEffect(e4)
end
s.listed_names={45231177} -- Flame Swordsman
s.listed_series={0x3b,0x130} -- Red-Eyes, Flame Swordsman
function s.lcheck(g,lc,tp)
	return g:FilterCount(Card.IsRace,nil,RACE_DRAGON,lc,SUMMON_TYPE_LINK,tp)==2
		or g:FilterCount(Card.IsRace,nil,RACE_WARRIOR,lc,SUMMON_TYPE_LINK,tp)==2
end
function s.atkfilter(c)
	return c:IsRace(RACE_DRAGON|RACE_WARRIOR) and c:IsFaceup()
end
function s.atkval(e,c)
	local g=c:GetLinkedGroup():Filter(s.atkfilter,nil)
	return #g*100
end
function s.tgcon(e)
	return e:GetHandler():GetLinkedGroup():FilterCount(Card.IsControler,nil,e:GetHandlerPlayer())>0
end
function s.tgval(e,re,rp)
	return rp==1-e:GetHandlerPlayer() and re:IsHasType(EFFECT_TYPE_ACTIONS)
end
function s.is_listed(c, code)
	if c:IsCode(code) then return true end
	if c.listed_names then
		for _,v in pairs(c.listed_names) do
			if v==code then return true end
		end
	end
	return false
end
function s.fusfilter(c,e,tp)
	if not (c:IsType(TYPE_FUSION) and (c:IsSetCard(0x3b) or c:IsSetCard(0x130) or c:IsCode(45231177) or s.is_listed(c,45231177))) then return false end
	local fusg=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,LOCATION_GRAVE,0,nil)
	return c:CheckFusionMaterial(fusg,nil,tp)
end
function s.ritmatfilter(c)
	return c:IsMonster() and c:IsLevelAbove(1) and c:IsAbleToDeck() and (c:IsFaceup() or c:IsLocation(LOCATION_GRAVE))
end
function s.ritfilter(c,e,tp)
	if not (c:IsType(TYPE_RITUAL) and c:IsMonster() and c:IsAttribute(ATTRIBUTE_FIRE|ATTRIBUTE_DARK) 
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,false,true)) then return false end
	local mg=Duel.GetMatchingGroup(s.ritmatfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
	local sum=0
	for tc in aux.Next(mg) do sum=sum+tc:GetLevel() end
	return sum>=c:GetLevel()
end
function s.efftg(e,tp,eg,ep,ev,re,r,rp,chk)
	local b1=Duel.GetTurnPlayer()==tp and Duel.IsExistingMatchingCard(s.fusfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp)
	local b2=Duel.GetTurnPlayer()~=tp and Duel.IsExistingMatchingCard(s.ritfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil,e,tp)
	if chk==0 then return b1 or b2 end
	if Duel.GetTurnPlayer()==tp then
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
		Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_GRAVE)
	else
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE)
		Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_GRAVE+LOCATION_REMOVED)
	end
end
function s.effop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetTurnPlayer()==tp then
		local fusg=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,LOCATION_GRAVE,0,nil)
		local cg1=Duel.GetMatchingGroup(s.fusfilter,tp,LOCATION_EXTRA,0,nil,e,tp)
		if #cg1>0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local sg=cg1:FilterSelect(tp,function(c) return c:CheckFusionMaterial(fusg,nil,tp) end,1,1,nil)
			local tc=sg:GetFirst()
			if tc then
				local mat=Duel.SelectFusionMaterial(tp,tc,fusg,nil,tp)
				tc:SetMaterial(mat)
				if Duel.Remove(mat,POS_FACEUP,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)>0 then
					Duel.BreakEffect()
					Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
					tc:CompleteProcedure()
				end
			end
		end
	else
		local mg=Duel.GetMatchingGroup(s.ritmatfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
		local cg1=Duel.GetMatchingGroup(s.ritfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,nil,e,tp)
		if #cg1>0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local sg=cg1:Select(tp,1,1,nil)
			local tc=sg:GetFirst()
			if tc then
				local lv=tc:GetLevel()
				local mat=Group.CreateGroup()
				local current_lv=0
				while current_lv<lv do
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
					local sg2=mg:FilterSelect(tp,function(c) return not mat:IsContains(c) end,1,1,nil)
					if #sg2==0 then break end
					mat:Merge(sg2)
					current_lv=current_lv+sg2:GetFirst():GetLevel()
				end
				if current_lv>=lv then
					tc:SetMaterial(mat)
					if Duel.SendtoDeck(mat,nil,SEQ_DECKSHUFFLE,REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL)>0 then
						Duel.BreakEffect()
						Duel.SpecialSummon(tc,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)
						tc:CompleteProcedure()
					end
				end
			end
		end
	end
end
