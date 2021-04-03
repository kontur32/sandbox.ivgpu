module namespace ivgpu = '/sandbox/ivgpu/plans.list';

declare variable  $ivgpu:folderList := 
  function( $id ){ 
    'https://portal.ivgpu.com/rest/374/59qoewl9ubg080rm/disk.folder.getchildren?id=' || $id
  };

declare variable  $ivgpu:getList :=
    function( $url ){
      json:parse(
       fetch:text( $url )
    )/json/result/_
  };

declare function ivgpu:getPlansList( $folderID, $folderName ){
  let $list := $ivgpu:getList( $ivgpu:folderList( $folderID ) )
  return
    (
      if( $list/TYPE = 'file' and not ( $list/NAME[ matches( ., '(.xml|.plx)$' ) ] ) )
      then(
        <_>
          <PARENT__ID>{ $folderID/text() }</PARENT__ID>
          <PARENT__NAME>{ $folderName/text() }</PARENT__NAME>
        </_>
      )
      else(
        for $f in $list[ TYPE = 'file' ][ matches( NAME, '(.xml|.plx)$') ]
        return
            $f update insert node <PARENT__NAME>{ $folderName/text() }</PARENT__NAME> into .
      ),
      
      for $f in $list[ TYPE = 'folder' ]
      return
        ivgpu:getPlansList( $f/ID, $f/NAME )  
    )
};

declare 
  %rest:path('/sandbox/ivgpu/plans.list')
  %rest:query-param('rootID', '{ $rootID }', '7266')
  %output:method( 'text' )
function ivgpu:main( $rootID ){
  let $result :=
    <json>
      { ivgpu:getPlansList( $rootID, '/' ) }
    </json>
 return

    for $i in $result/child::*
    order by $i/NAME/text()
    count $c
    return
        $c || ') ' || $i/PARENT__NAME/text() ||
        ' (ID : ' || $i/PARENT__ID/text() || ') ' ||
        'РУП : ' || $i/NAME/text() || ' (ID : ' || $i/ID/text() || ')' ||
        '&#xd;'
};