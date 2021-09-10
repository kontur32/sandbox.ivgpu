module namespace graduation  = 'graduation.root';

import module namespace request = "http://exquery.org/ns/request";
import module namespace session = "http://basex.org/modules/session";

import module namespace 
  bitrix.disk = 'bitrix.disk' 
    at '../modules/bitrix.disk.xqm';

declare variable $graduation:folderID := '428956';

declare 
  %rest:path( '/sandbox/ivgpu/graduation/{ $year }/{ $department }/groups' )
  %output:method( 'xhtml' )
function graduation:view( $year, $department ){
  let $группы := 
    bitrix.disk:getFileXLSX( $graduation:folderID, map{ 'recursive' : 'yes', 'name' : 'Список групп.xlsx' } )
  let $спискиГруппЗагруженные := 
    bitrix.disk:getFileList( $graduation:folderID, map{ 'recursive' : 'yes', 'name' : '.' } )/NAME/substring-before( text(), '.' )[ matches( ., '-[0-9]{2}' ) ]
  
  let $провекаПодписей := 
    graduation:провекаПодписей( $graduation:folderID, '.xlsx$' )
  
  let $списокГрупп :=
    <div>Выпускные группы кафедры "{ $department }" в { $year } году:
      <table class = "table">
      <tr>
        <th>Группа</th>
        <th>Наличие ЭЦП</th>
        <th></th>
      </tr>
      {
        for $i in $группы/file/table[ 1 ]/row
        let $номерГруппы := $i/cell[ @label = "Группа" ]/text()
        let $href := 'groups/' || $номерГруппы
        let $hrefСлужебка := 
          '/sandbox/ivgpu/generate/Служебная/21/ТемыВКР/' || $номерГруппы
        let $кнопка := 
           if( $провекаПодписей[ ?1 = $номерГруппы ]?2 )
           then( "btn btn-success" )
           else( "btn btn-info" )
        return
           <tr>
             <td><a href = "{ $href }">{ $номерГруппы }</a></td>
             
               <td>{
                 if( $провекаПодписей[ ?1 = $номерГруппы ]?2 )
                 then( 'подписана' )
                 else()
               }</td>
             <td>
               {
                 if( $номерГруппы = $спискиГруппЗагруженные )
                 then(
                   <a href = "{ $hrefСлужебка }" class="{ $кнопка }">Скачать служебку на темы</a>
                 )
                 else()
               }</td>
           </tr>
      }
      </table>
    </div>
    
  let $tpl := doc( "../html/main.tpl.html" )
  return
    $tpl update insert node <div>{ $списокГрупп }</div> into .//body
};

declare function graduation:провекаПодписей( $folderID, $mask ){
  let $писокФайлов := 
    bitrix.disk:getFileList(  $folderID, map{ 'recursive' : 'yes', 'name' : $mask } )
  let $списокПодписей := 
    bitrix.disk:getFileList(  $folderID, map{ 'recursive' : 'yes', 'name' : '.sig$' } )
  
   for $i in $писокФайлов
   let $имяФайла := $i/NAME/text()
   let $файл := fetch:binary( $i/DOWNLOAD__URL/text() ) 
   let $имяФайлаПодписи := $имяФайла || '.sig'
   let $путьФайлаПодписи := 
     $списокПодписей[ starts-with( NAME/text(), $имяФайла ) ]/DOWNLOAD__URL/text()
   let $подпись :=
     if( $путьФайлаПодписи )then( fetch:text( $путьФайлаПодписи ) )else()
   return
     [ tokenize( $имяФайла, '\.' )[ 1 ],  $подпись = string( hash:sha256( $файл ) ) ]
};