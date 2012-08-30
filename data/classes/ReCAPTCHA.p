#
# based on:
# http://www.parser.ru/forum/?id=74713
# http://www.parser.ru/forum/?id=74745
#

@CLASS
ReCAPTCHA

@auto[]

	$self.sChallengeURL[http://www.google.com/recaptcha/api/challenge]
	$self.sNoscriptChallengeURL[http://www.google.com/recaptcha/api/noscript]
	$self.sAJAXURL[http://www.google.com/recaptcha/api/js/recaptcha_ajax.js]
	$self.sVerifyURL[http://www.google.com/recaptcha/api/verify]


@create[]


@printHTML[sPublicKey;sErrorCode][sError]

	$sError[]
	^if(def $sErrorCode){
		$sError[&amp^;error=$sErrorCode]
	}

$result[^if(def $sErrorCode){<style>.recaptcha-label {color: red}</style>}
<script type="text/javascript" src="${self.sChallengeURL}?k=${sPublicKey}$sError"></script>
<noscript>
	<iframe src="${self.sNoscriptChallengeURL}?k=${sPublicKey}$sError" height="300" width="500" frameborder="0"></iframe><br/>
	<textarea name="recaptcha_challenge_field" rows="3" cols="40"></textarea>
	<input type="hidden" name="recaptcha_response_field" value="manual_challenge"/>
</noscript>]


@printAJAX[sPublicKey;sErrorCode][sField;sValue]

$result[<div id="recaptcha_container"></div>
<script type="text/javascript" src="$self.sAJAXURL"></script>
<script type="text/javascript">
	Recaptcha.create("$sPublicKey", "recaptcha_container")^;
</script>]


@verify[sPrivateKey;hData][fResult;tResult]

	$result[^hash::create[]]

	$fResult[^file::load[text;$self.sVerifyURL][
		$.method[POST]
		$.form[
			$.privatekey[$sPrivateKey]
			$.remoteip[$env:REMOTE_ADDR]
			$.challenge[$hData.recaptcha_challenge_field]
			$.response[$hData.recaptcha_response_field]
		]
		$.headers[
			$.[USER-AGENT][reCAPTCHA Parser3]
		]
		$.timeout(10)
	]]

	$tResult[^table::create[nameless]{^taint[as-is][$fResult.text]}]
	$result.valid(^tResult.0.bool(false))
	^tResult.offset(1)
	$result.errorcode[$tResult.0]
