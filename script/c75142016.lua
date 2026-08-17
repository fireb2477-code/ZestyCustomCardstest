-- Red-Eyes Metal Ultimate Dragon
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	Fusion.AddProcMixN(c,true,true,s.matfilter,3)
	-- Special Summon procedure
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetCondition(s.sprcon)
	e0:SetTarget(s.sprtg)
	e0:SetOperation(s.sprop)
	c:RegisterEffect(e0)
	-- Destroy
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_ATKCHANGE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.descon)
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)
	-- Multi attack and pierce
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_EXTRA_ATTACK)
	e2:SetCondition(s.atkcon)
	e2:SetValue(2)
	c:RegisterEffect(e2)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_PIERCE)
	e3:SetCondition(s.atkcon)
	c:RegisterEffect(e3)
	-- Material check
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_MATERIAL_CHECK)
	e4:SetValue(s.valcheck)
	e4:SetLabelObject(e2)
	c:RegisterEffect(e4)
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetCode(EFFECT_MATERIAL_CHECK)
	e5:SetValue(s.valcheck)
	e5:SetLabelObject(e3)
	c:RegisterEffect(e5)
end
s.material_setcode={0x3b}
s.listed_names={64335804,68540058,80870883,89812483}
function s.matfilter(c,fc,sumtype,sump,sub,matg,sg)
	return c:IsSetCard(0x3b,fc,sumtype,sump) and (not sg or sg:FilterCount(aux.TRUE,c)==0 or not sg:IsExists(s.fusfilter,1,c,c:GetCode(fc,sumtype,sump),fc,sumtype,sump))
end
function s.fusfilter(c,code,fc,sumtype,sump)
	return c:IsSummonCode(fc,sumtype,sump,code) and not c:IsHasEffect(511002961)
end
function s.spfilter1(c,code)
	return c:IsCode(code) and c:IsAbleToRemoveAsCost()
end
function s.sprcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	local b1=Duel.IsExistingMatchingCard(s.spfilter1,tp,LOCATION_ONFIELD+LOCATION_GRAVE,0,1,nil,64335804)
		and Duel.IsExistingMatchingCard(s.spfilter1,tp,LOCATION_ONFIELD+LOCATION_GRAVE,0,1,nil,68540058)
	local b2=Duel.IsExistingMatchingCard(s.spfilter1,tp,LOCATION_ONFIELD+LOCATION_GRAVE,0,1,nil,80870883)
		and Duel.IsExistingMatchingCard(s.spfilter1,tp,LOCATION_ONFIELD+LOCATION_GRAVE,0,1,nil,89812483)
	return Duel.GetLocationCountFromEx(tp,tp,nil,c)>0 and (b1 or b2)
end
function s.sprtg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local b1=Duel.IsExistingMatchingCard(s.spfilter1,tp,LOCATION_ONFIELD+LOCATION_GRAVE,0,1,nil,64335804)
		and Duel.IsExistingMatchingCard(s.spfilter1,tp,LOCATION_ONFIELD+LOCATION_GRAVE,0,1,nil,68540058)
	local b2=Duel.IsExistingMatchingCard(s.spfilter1,tp,LOCATION_ONFIELD+LOCATION_GRAVE,0,1,nil,80870883)
		and Duel.IsExistingMatchingCard(s.spfilter1,tp,LOCATION_ONFIELD+LOCATION_GRAVE,0,1,nil,89812483)
	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,1),aux.Stringid(id,2))
	elseif b1 then op=0 else op=1 end
	local g=Group.CreateGroup()
	if op==0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		local g1=Duel.SelectMatchingCard(tp,s.spfilter1,tp,LOCATION_ONFIELD+LOCATION_GRAVE,0,1,1,nil,64335804)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		local g2=Duel.SelectMatchingCard(tp,s.spfilter1,tp,LOCATION_ONFIELD+LOCATION_GRAVE,0,1,1,nil,68540058)
		g:Merge(g1)
		g:Merge(g2)
	else
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		local g1=Duel.SelectMatchingCard(tp,s.spfilter1,tp,LOCATION_ONFIELD+LOCATION_GRAVE,0,1,1,nil,80870883)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		local g2=Duel.SelectMatchingCard(tp,s.spfilter1,tp,LOCATION_ONFIELD+LOCATION_GRAVE,0,1,1,nil,89812483)
		g:Merge(g1)
		g:Merge(g2)
	end
	if g then
		g:KeepAlive()
		e:SetLabelObject(g)
		return true
	end
	return false
end
function s.sprop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	if not g then return end
	Duel.Remove(g,POS_FACEUP,REASON_COST)
	c:SetMaterial(g)
	g:DeleteGroup()
end
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==1 or Duel.GetLP(tp)~=8000
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(nil,tp,0,LOCATION_MZONE,1,nil) end
	local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_MZONE,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_MZONE,nil)
	local ct=Duel.Destroy(g,REASON_EFFECT)
	if ct>0 and e:GetHandler():IsRelateToEffect(e) and e:GetHandler():IsFaceup() then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(ct*100)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
		e:GetHandler():RegisterEffect(e1)
	end
end
function s.valcheck(e,c)
	local g=c:GetMaterial()
	if g:IsExists(Card.IsCode,1,nil,64335804,80870883) then
		e:GetLabelObject():SetLabel(1)
	else
		e:GetLabelObject():SetLabel(0)
	end
end
function s.atkcon(e)
	return e:GetLabel()==1 or e:GetHandler():GetMaterial():IsExists(Card.IsCode,1,nil,64335804,80870883)
end
