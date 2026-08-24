-- Bookey Supabase schema (PRD section 6).
-- Run this once against a fresh Supabase project (SQL editor or `supabase db push`).

-- teachers: Supabase Auth 사용자와 1:1 (id = auth.users.id)
create table public.teachers (
  id          uuid primary key references auth.users(id) on delete cascade,
  name        text not null default '',
  created_at  timestamptz not null default now()
);

-- students: 선생님이 등록한 학생 이름
create table public.students (
  id          uuid primary key default gen_random_uuid(),
  teacher_id  uuid not null references public.teachers(id) on delete cascade,
  name        text not null,
  created_at  timestamptz not null default now()
);

-- books: 선생님이 등록한 책 목록
create table public.books (
  id          uuid primary key default gen_random_uuid(),
  teacher_id  uuid not null references public.teachers(id) on delete cascade,
  title       text not null,
  cover_url   text,
  order_index integer not null default 0,
  created_at  timestamptz not null default now()
);

-- book_reads: 학생별 "읽음 체크" 기록. 행이 존재하면 체크된 것.
create table public.book_reads (
  student_id  uuid not null references public.students(id) on delete cascade,
  book_id     uuid not null references public.books(id) on delete cascade,
  teacher_id  uuid not null references public.teachers(id) on delete cascade,
  checked_at  timestamptz not null default now(),
  primary key (student_id, book_id)
);

-- 조회 성능: 학생별 책 목록 화면 진입 시 student_id로 book_reads를 조회하고,
-- 관리자 화면에서 teacher_id로 students/books를 조회하는 경로에 인덱스를 둔다.
create index students_teacher_id_idx on public.students(teacher_id);
create index books_teacher_id_idx on public.books(teacher_id);
create index book_reads_student_id_idx on public.book_reads(student_id);

-- RLS
alter table public.teachers enable row level security;
alter table public.students enable row level security;
alter table public.books enable row level security;
alter table public.book_reads enable row level security;

create policy "teacher manages own row" on public.teachers
  for all using (auth.uid() = id) with check (auth.uid() = id);

create policy "teacher manages own students" on public.students
  for all using (auth.uid() = teacher_id) with check (auth.uid() = teacher_id);

create policy "teacher manages own books" on public.books
  for all using (auth.uid() = teacher_id) with check (auth.uid() = teacher_id);

create policy "teacher manages own book_reads" on public.book_reads
  for all using (auth.uid() = teacher_id) with check (auth.uid() = teacher_id);
