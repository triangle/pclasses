@CLASS
FilePackage



@init[hParams]
$hParams[^hash::create[$hParams]]

$oEngine[$hParams.oEngine]
$oSql[$self.oEngine.oSql]

$sPackageBody[$hParams.sBody]
$iPackageObjectId($hParams.iPackageObjectId)

$bRebuildPackage(false)

$sCacheDir[$MAIN:CACHE_DIR/_package]

$tFile[^table::create{src	date_modified}]



@print[]
$result[^oEngine.modifyXML[$sPackageBody;$_printPackage;package;package;(name)\s*=\s*"[^^"]+"]]



@_printPackage[sType;hParam;hConfig][oPackageObject]
$sPackageName[$hParam.oAttrs.name]
$sPackageSrc[^oEngine.objectFile[$sPackageName;^oEngine.getObjectById($iPackageObjectId)]]

$iCacheTime($hParam.oAttrs.cache)

^if(!$iCacheTime){
	^if($iPackageObjectId == $oEngine.currentObjectId){
		$iCacheTime(^oEngine.getCacheTime[])
	}{
		$oPackageObject[^oEngine.getObjectById[$iPackageObjectId]]
		$iCacheTime(^oPackageObject.cache_time.int($MAIN:iCacheTimeDefault))
	}
}

$sCacheKey[${iPackageObjectId}_$sPackageName]

^if(!-f $sPackageSrc){
	$bRebuildPackage(true)
	$iCacheTime(0)
}

$result[^cache[$sCacheDir/$sCacheKey]($iCacheTime){

	^self._loadFileStats[]
	
	^oEngine.modifyXML[$hParam.sBody;$_processFileInPackage;file;file;(src)\s*=\s*"[^^"]+"]
	
	^self._processPackage[$tFile;$hParam]
	
}]



@_processFileInPackage[sType;hParam;hConfig][fFile]
$fFile[^file::stat[$hParam.oAttrs.src]]

$bRebuildPackage($bRebuildPackage || !^hFileStats.contains[$hParam.oAttrs.src] || ^date::create[$hFileStats.[$hParam.oAttrs.src].date_modified] < $fFile.mdate)

^tFile.append{$hParam.oAttrs.src	^fFile.mdate.sql-string[]}



@_processPackage[tFile;hParam][locals]

^if($bRebuildPackage){
	^tFile.menu{
		$fFile[^file::load[text;$tFile.src]]
		$sPackageFileBody[^if(def $sPackageFileBody){$sPackageFileBody^#0A}$fFile.text]
	}
	
	^if(^sPackageFileBody.trim[] ne ''){
		^sPackageFileBody.save[$sPackageSrc]
	}
}

^if($tFile){
	$result[<file alias="$sPackageName" object-id="$iPackageObjectId" />]
	
	$result[^oEngine.modifyXML[$result;$oEngine.printElement;file;file;(alias)\s*=\s*"[^^"]+"]]
	
	$sDateAddon[^oEngine.dtNow.sql-string[]]
	$sDateAddon[^sDateAddon.match[\D][g]{}]
	
	$result[^result.match[src="([^^"]+)"][]{src="$match.1?$sDateAddon"}]
}

^if($bRebuildPackage){
	^self._saveFileStats[]
}



@_loadFileStats[]

$tFileStats[^oSql.table{
	SELECT
		file_src AS src
		, file_date_modified AS date_modified
	FROM
		file_package
	WHERE
		package_object_id = $iPackageObjectId
		AND package_name = '$sPackageName'
}]

$hFileStats[^tFileStats.hash[src]]



@_saveFileStats[]
^oSql.void{
	DELETE FROM file_package
	WHERE
		package_object_id = $iPackageObjectId
		AND package_name = '$sPackageName'
}

^oSql.void{
	INSERT INTO file_package (
		package_object_id
		, package_name
		, file_src
		, file_date_modified
	) VALUES
	^tFile.menu{(
		$iPackageObjectId
		, '$sPackageName'
		, '$tFile.src'
		, '$tFile.date_modified'
	)}[,]
}