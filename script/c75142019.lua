-- Neo Gearfried, Master of The Red-Eyes
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	Fusion.AddProcMixN(c,true,true,s.matfilter,2)
	-- Attack directly
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_DIRECT_ATTACK)
	c:RegisterEffect(e1)
	-- Return to hand and ATK
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_ATKCHANGE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	-- Multi attack
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_EXTRA_ATTACK)
	e3:SetValue(s.atkval)
	c:RegisterEffect(e3)
end
s.material_setcode={0x3b}
function s.matfilter(c,fc,sumtype,sump,sub,matg,sg)
	return c:IsSetCard(0x3b,fc,sumtype,sump) and (not sg or sg:FilterCount(aux.TRUE,c)==0 or not sg:IsExists(s.fusfilter,1,c,c:GetCode(fc,sumtype,sump),fc,sumtype,sump))
end
function s.fusfilter(c,code,fc,sumtype,sump)
	return c:IsSummonCode(fc,sumtype,sump,code) and not c:IsHasEffect(511002961)
end
function s.refilter(c)
	return c:IsSetCard(0x3b) and c:IsFaceup()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(1-tp) and chkc:IsOnField() and chkc:IsAbleToHand() end
	if chk==0 then return Duel.IsExistingMatchingCard(s.refilter,tp,LOCATION_ONFIELD,0,1,nil)
		and Duel.IsExistingTarget(Card.IsAbleToHand,tp,0,LOCATION_ONFIELD,1,nil) end
	local ct=Duel.GetMatchingGroupCount(s.refilter,tp,LOCATION_ONFIELD,0,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local g=Duel.SelectTarget(tp,Card.IsAbleToHand,tp,0,LOCATION_ONFIELD,1,ct,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,#g,0,0)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	if #g>0 then
		local ct=Duel.SendtoHand(g,nil,REASON_EFFECT)
		local c=e:GetHandler()
		if ct>0 and c:IsRelateToEffect(e) and c:IsFaceup() then
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetValue(ct*700)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
			c:RegisterEffect(e1)
		end
	end
end
function s.eqfilter(c)
	return c:IsSetCard(0x3b)
end
function s.atkval(e,c)
	local g=c:GetEquipGroup()
	if not g then return 0 end
	return g:FilterCount(s.eqfilter,nil)
end
