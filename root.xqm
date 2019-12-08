module namespace ivgpu = 'subjects.Departments.List';


declare 
  %rest:path( '/sandbox/ivgpu' )
  %output:method( 'xhtml' )
function ivgpu:view(){
  <div>
    <h2>Точки доступа сервиса <i>simplex</i></h2>
    <ul>
      <li><a href = '/sandbox/ivgpu/subjects.Department.Direction?id=36&amp;mode=other'>Списки дисцпилн по РУПам</a></li>
      <li><a href = '/sandbox/ivgpu/subjects.Departments.List?mode=other&amp;id=29'>Список дисциплин по кафедре</a></li>
    </ul>
    <p><a href = 'http://iro37.ru/xqwiki/TRaC/simplex'>справка по сервису</a></p>
  </div>
};