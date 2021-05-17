module namespace cache = '/sandbox/ivgpu/api/v01/generate/rpd/cache';

import module namespace config = '/sandbox/ivgpu/api/v01/generate/config'
  at '../config.xqm';
  
import module namespace data = '/sandbox/ivgpu/generate/data'
  at '../../generate.doc/generate.data.xqm';


declare
  %public
function cache:getFolderID(
  $индентификаторКорневойПапки as xs:string,
  $ID as xs:string,
  $params as map(*)
)
  as xs:string
{
   let $path := 
     config:param( 'host') ||
     string-join(
        (
          '/sandbox/ivgpu/api/v01/generate/rpd', $ID , 'folder.id', $индентификаторКорневойПапки
        ), '/' )
   return     
     data:getResourceCSV( $path, $params )//record/folderID/text()
};