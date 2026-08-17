-- Super Red-Eyes Fusion
local s,id=GetID()
function s.initial_effect(c)
	-- Fusion Summon
	local e1=Fusion.CreateSummonEff({
		handler=c,
		filter=s.ffilter,
		matfilter=Card.IsOnField,
		extrafil=s.fextra,
		stage2=s.stage2
	})
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	c:RegisterEffect(e1)
end
s.listed_series={0x3b}
function s.ffilter(c)
	return c:IsAttribute(ATTRIBUTE_DARK) and c:IsRace(RACE_DRAGON)
end
function s.fcheck(tp,sg,fc)
	if sg:IsExists(Card.IsLocation,1,nil,LOCATION_DECK) then
		return fc:IsSetCard(0x3b)
	end
	return true
end
function s.fextra(e,tp,mg)
	local eg=Duel.GetMatchingGroup(nil,tp,0,LOCATION_MZONE,nil)
	local dg=Duel.GetMatchingGroup(Card.IsAbleToGrave,tp,LOCATION_DECK,0,nil)
	eg:Merge(dg)
	return eg,s.fcheck
end
function s.stage2(e,tc,tp,mg,chk)
	if chk==1 then
		local c=e:GetHandler()
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e1:SetCode(EVENT_PHASE+PHASE_END)
		e1:SetCountLimit(1)
		e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
		e1:SetLabelObject(tc)
		e1:SetCondition(s.rmcon)
		e1:SetOperation(s.rmop)
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)
		tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1)
	end
end
function s.rmfilter(c,tc)
	return c:IsSetCard(0x3b) and c:IsFaceup() and c~=tc
end
function s.rmcon(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	if tc:GetFlagEffect(id)==0 then
		e:Reset()
		return false
	end
	return not Duel.IsExistingMatchingCard(s.rmfilter,tp,LOCATION_MZONE,0,1,nil,tc)
end
function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)
end
