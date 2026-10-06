-- باغ‌یار: ردیف و ستون/موقعیت درخت
alter table public.trees add column if not exists column_no text;
create index if not exists trees_user_plot_row_idx on public.trees(user_id, plot_id, row_no, column_no);
