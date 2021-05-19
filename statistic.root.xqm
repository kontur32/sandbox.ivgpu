module namespace statistic = 'statistic.root';

import module namespace request = "http://exquery.org/ns/request";
import module namespace session = "http://basex.org/modules/session";

declare 
  %rest:path( '/sandbox/ivgpu/statistic' )
  %output:method( 'xhtml' )
function statistic:view(){
 let $authURL :=
   'https://accounts.ivgpu.com/login?redirect=' ||
   'https://sm.ivgpu.com/sandbox/ivgpu/statistic/login?redirect=https://sm.ivgpu.com/sandbox/ivgpu/statistic'
 
 let $body :=
  <div>
    <h2>Точки доступа сервиса статистики ООП ИВГПУ <i>simplex</i></h2>
    <ul>
      <li>
        <a href = '/sandbox/ivgpu/directions'>Cписки дисцплин по направлениям и программам</a>
      </li>
      <li>
        <a href = '/sandbox/ivgpu/subjects.Department.Direction?id=21&amp;mode=full'>Списки дисцплин по кафедрам</a>
      </li>
      <li><a href = '/sandbox/ivgpu/statistic/oop.subjects.dep'>Общая статистика по количетсву ООП и дисциплин по университету</a>
      </li>
    </ul>
    <h3>Инструкции по сервису</h3>
    <ul>
      <li><a target = '_blank' href = 'https://docs.google.com/document/d/e/2PACX-1vSp5udo0w2YbXMom5K0V_8RgUqv5MUc1IprBqBOW8rlwW68k5ZXbTcJ635KeG_c3RlAJ4PYkQ8EuKM5/pub'>автогенерация РПД</a></li>
      <li><a target = '_blank' href = 'https://docs.google.com/document/d/e/2PACX-1vS6Ja0SNukIT7FRmgmHtdrL1TsGqZF78OdrzY2BiGBIDFBxoP0tyiw-n-ZvLdzA_0Gb5_OipgwFuuJq/pub'>работа со списками дисциплин</a></li>
    </ul>
    {
      if( session:get( 'login' ) )
      then(
        <div>
          <a href = 'https://sm.ivgpu.com/sandbox/ivgpu/statistic/logout' class="btn btn-lg btn-primary" >Выйти</a>
        </div>
      )
      else(       
        <div >
          <h3>Войти с использованием учетной записи <a href = 'https://accounts.ivgpu.com/'>ЭИС ПОЛИТЕХ</a>:</h3>
          <a href = '{ $authURL }' type="button" class="btn btn-lg btn-primary" >ВОЙТИ</a>
        </div>
 
      )
    }
    {
      if( session:get( 'login' ) )
      then(
        <div>пользователь: { session:get( 'userName' ) } ({ session:get( 'login' ) }) кафедра: { session:get( 'department' ) }</div>
      )
      else()
    }
    
  </div>
  let $tpl := doc( "html/main.tpl.html" )
  return
    $tpl update insert node $body into .//body
};