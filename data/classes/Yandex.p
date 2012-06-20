# Class for Yandex.Server
# Author: chesco

@CLASS
Yandex

###########################################################################
@auto[]

	$sClassName[Yandex]
	
	$iDefaultNumdoc(50)
	$iDefaultNumpergroup(20)
	
	$hGetConfig[
		$.serverUrl[http://localhost:17000/]
		$.numdoc($iDefaultNumdoc)	^rem{ not used if 'grouping' is true }
		$.numpergroup($iDefaultNumpergroup) ^rem{ used if 'grouping' is true, 'numdoc' ignored }
		$.charset[UTF-8]
		$.collection[]
		$.section[]		^rem{ comma separated ids of sections }
		$.sections(0)	^rem{ count of sections for grouping }
		$.segment[]		^rem{ comma separated ids of segments }
		$.grouping[]	^rem{ if true, 'section' ignored }
		$.user[]
		$.password[]
		$.timeout(120)
	]
	

###########################################################################
@create[hParam]

	$hParam[^hash::create[$hParam]]
	$self.hParam[^hParam.union[$CLASS.hGetConfig]]
	$self.hParam.serverUrl[^taint[as-is][^self.hParam.serverUrl.trim[end;/]/]]
	$self.tSection[]
	$self.tSegment[]
	
	^if(def $self.hParam.section){
		$self.tSection[^self.hParam.section.split[,;v;name]]
	}
	^if(def $self.hParam.segment){
		$self.tSegment[^self.hParam.segment.split[,;v;name]]
	}


###########################################################################
@search[sText][hForm;sTmp]

	$sText[^sText.trim[]]
	$result[]

	^if(def $sText){
		^try{
			$hForm[
				$.text[$sText]
				$.p(^form:p.int(0))
				$.xml[yes]
			]
			$hForm.numdoc(^self.hParam.numdoc.int($CLASS.iDefaultNumdoc))
			^if($self.hParam.grouping){
				$hForm.g[1.section.^self.hParam.sections.int(0).^self.hParam.numpergroup.int($CLASS.iDefaultNumpergroup).-1]
			}{
				^if(def $self.tSection){
					$hForm.text[${hForm.text} && (]
					$hForm.text[${hForm.text} ^self.tSection.menu{#section="$self.tSection.name"}[|]]
					$hForm.text[${hForm.text})]
				}
			}
			^if(def $self.tSegment){
				$hForm.text[${hForm.text} && (]
				$hForm.text[${hForm.text} ^self.tSegment.menu{#segment="$self.tSegment.name"}[|]]
				$hForm.text[${hForm.text})]
			}
			$result[^file::load[text;${self.hParam.serverUrl}${self.hParam.collection};
				$.form[$hForm]
				$.charset[$self.hParam.charset]
				^if(def $self.hParam.user){
					$.user[$self.hParam.user]
					$.password[$self.hParam.password]
				}
				$.timeout($self.hParam.timeout)
			]]
			$sTmp[<?xml version="1.0" encoding="${self.hParam.charset}"?>]
			$result[^result.text.mid(^sTmp.length[])
				^self.pringConfig[$sText]
			]
		}{
			$exception.handled(!^MAIN:isDeveloper[])
			$result[<search-failed />]
		}
	}


###########################################################################
@pringConfig[sText][t]

	$result[<config>
	^self.hParam.foreach[k;v]{
		^switch[$k]{
			^case[user;password]{}
			^case[section]{^if(def $self.tSection){<section>
				^self.tSection.menu{<item>$self.tSection.name</item>}
			</section>}}
			^case[segment]{^if(def $self.tSegment){<segment>
				^self.tSegment.menu{<item>$self.tSegment.name</item>}
			</segment>}}
			^case[DEFAULT]{<$k>$v</$k>}
		}
	}<query-hash>^math:md5[${self.hParam.collection}_${sText}_^if(def $self.tSegment){^self.tSegment.menu{$self.tSegment.name}[_]}]</query-hash>
	</config>]
